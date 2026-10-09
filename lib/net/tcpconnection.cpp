//
// tcpconnection.cpp
//
// This implements RFC 793 with some changes in RFC 1122 and RFC 6298
// and with congestion control in RFC 5681.
//
// Non-implemented features:
//	dynamic receive window
//	URG flag and urgent pointer
//	delayed ACK (not recommended any more)
//	security/compartment
//	precedence
//	user timeout
//
// Circle - A C++ bare metal environment for Raspberry Pi
// Copyright (C) 2015-2026  R. Stange <rsta2@gmx.net>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
#include <circle/net/tcpconnection.h>
#include <circle/net/sizes.h>
#include <circle/net/error.h>
#include <circle/macros.h>
#include <circle/util.h>
#include <circle/logger.h>
#include <circle/net/in.h>
#include <assert.h>

//#define TCP_DEBUG

#define TCP_MAX_CONNECTIONS		1000	// maximum number of active TCP connections

					// maximum segment size to be received from network layer
#define TCP_MSS_R			(ETH_MAX_LEN - ETH_HEADER_LEN - IP_HEADER_LEN)
					// maximum segment size to be send to network layer
#define TCP_MSS_S			(ETH_MAX_LEN - ETH_HEADER_LEN - IP_HEADER_LEN)

#define TCP_CONFIG_MSS			(TCP_MSS_R - TCP_HEADER_LEN)
#define TCP_CONFIG_WINDOW		(TCP_CONFIG_MSS * 44)	// Onyx: 64240 (was 10 MSS: 14600)

// Onyx: with window scaling (RFC 7323: both SYNs carry the option) the receive window is 180
// segments (262800 bytes), sent shifted right by 3. 64 KB a round trip was the ceiling of every
// download: 2.5 MB/s at 25 ms, and 4.5 MB/s on the LAN (the queueing's 14 ms).
#define TCP_CONFIG_WINDOW_SCALED	(TCP_CONFIG_MSS * 180)
#define TCP_CONFIG_WINDOW_SHIFT		3
#define TCP_CONFIG_SSTHRESH_SCALED	0x100000	// initial slow-start threshold with a scaled peer window

extern "C" { int onyx_tcp_ws = 0; }
extern "C" { int onyx_tcp_window = 180; }
extern "C" { int onyx_tcp_trace = 0; }
extern "C" { int onyx_tcp_ackn = 2; }		// (onyx_tcp_ws & 2) full segments for one acknowledgement		// a line in the log at each retransmission timeout	// the scaled receive window, in segments (at most 180)
// (statistics, read and cleared by the Wi-Fi driver's link line: retransmissions after a timeout,
// fast retransmissions, the longest retransmission timeout that ran out, in ticks)
extern "C" { unsigned onyx_tcp_rto_count, onyx_tcp_fast_count, onyx_tcp_rto_max; }		// the switch (0: as before -- no option, a constant 64 KB window)

						// TX stops, if this number of bytes is queued
#define TCP_CONFIG_TX_THRESHOLD		(onyx_tcp_ws ? 0x40000u : 0x10000u)
#define TCP_CONFIG_RX_THRESHOLD		0x10000	// kicks RX, if this number of bytes is queued

#define TCP_MAX_WINDOW			((u16) -1)	// without Window extension option
#define TCP_QUIET_TIME			30	// seconds after crash before another connection starts

#define HZ_TIMEWAIT			(60 * HZ)
#define HZ_FIN_TIMEOUT			(60 * HZ)	// timeout in FIN-WAIT-2 state

// Onyx: the minimum RTO is 1 s (retranstimeoutcalc.cpp: 200 ms was tried and undone), so the
// upstream 5 tries (63 s) stay. A SYN: 5 (1 s initial RTO: 63 s; was 189 s from 3 s).
#define MAX_RETRANSMISSIONS		5
#define MAX_SYN_RETRANSMISSIONS		5

struct TTCPHeader
{
	u16 	nSourcePort;
	u16 	nDestPort;
	u32	nSequenceNumber;
	u32	nAcknowledgmentNumber;
	u16	nDataOffsetFlags;		// following #define(s) are valid without BE()
#define TCP_DATA_OFFSET(field)	(((field) >> 4) & 0x0F)
#define TCP_DATA_OFFSET_SHIFT	4
//#define TCP_FLAG_NONCE		(1 << 0)
//#define TCP_FLAG_CWR		(1 << 15)
//#define TCP_FLAG_ECN_ECHO	(1 << 14)
#define TCP_FLAG_URGENT		(1 << 13)
#define TCP_FLAG_ACK		(1 << 12)
#define TCP_FLAG_PUSH		(1 << 11)
#define TCP_FLAG_RESET		(1 << 10)
#define TCP_FLAG_SYN		(1 << 9)
#define TCP_FLAG_FIN		(1 << 8)
	u16	nWindow;
	u16	nChecksum;
	u16	nUrgentPointer;
	u32	Options[];
}
PACKED;

ASSERT_STATIC (sizeof (TTCPHeader) == TCP_HEADER_LEN);

struct TTCPOption
{
	u8	nKind;			// Data:
#define TCP_OPTION_END_OF_LIST	0	//	None (no length field)
#define TCP_OPTION_NOP		1	//	None (no length field)
#define TCP_OPTION_MSS		2	//	Maximum segment size (2 byte)
#define TCP_OPTION_WINDOW_SCALE	3	//	Shift count (1 byte)
#define TCP_OPTION_SACK_PERM	4	//	None
#define TCP_OPTION_TIMESTAMP	8	//	Timestamp value, Timestamp echo reply (2*4 byte)
	u8	nLength;
	u8	Data[];
}
PACKED;

#define min(n, m)		((n) <= (m) ? (n) : (m))
#define max(n, m)		((n) >= (m) ? (n) : (m))

// Modulo 32 sequence number arithmetic
#define lt(x, y)		((int) ((u32) (x) - (u32) (y)) < 0)
#define le(x, y)		((int) ((u32) (x) - (u32) (y)) <= 0)
#define gt(x, y) 		lt (y, x)
#define ge(x, y) 		le (y, x)

#define bw(l, x, h)		(lt ((l), (x)) && lt ((x), (h)))	// between
#define bwl(l, x, h)		(le ((l), (x)) && lt ((x), (h)))	//	low border inclusive
#define bwh(l, x, h)		(lt ((l), (x)) && le ((x), (h)))	//	high border inclusive
#define bwlh(l, x, h)		(le ((l), (x)) && le ((x), (h)))	//	both borders inclusive

#if !defined (NDEBUG) && defined (TCP_DEBUG)
	#define NEW_STATE(state)	NewState (state, __LINE__);
#else
	#define NEW_STATE(state)	(m_State = state)
#endif

#ifndef NDEBUG
	#define UNEXPECTED_STATE()	UnexpectedState (__LINE__)
#else
	#define UNEXPECTED_STATE()	((void) 0)
#endif

#define FLIGHT_SIZE 			(m_nSND_NXT - m_nSND_UNA)	// for congestion control

unsigned CTCPConnection::s_nConnections = 0;

const char *CTCPConnection::s_pStateName[] =	// must match TTCPState
{
	"CLOSED",
	"LISTEN",
	"SYN-SENT",
	"SYN-RECEIVED",
	"ESTABLISHED",
	"FIN-WAIT-1",
	"FIN-WAIT-2",
	"CLOSE-WAIT",
	"CLOSING",
	"LAST-ACK",
	"TIME-WAIT"
};

static const char FromTCP[] = "tcp";

CTCPConnection::CTCPConnection (CNetConfig	*pNetConfig,
				CNetworkLayer	*pNetworkLayer,
				const CIPAddress &rForeignIP,
				u16		 nForeignPort,
				u16		 nOwnPort)
:	CNetConnection (pNetConfig, pNetworkLayer, rForeignIP, nForeignPort, nOwnPort, IPPROTO_TCP),
	m_bActiveOpen (TRUE),
	m_State (TCPStateClosed),
	m_nErrno (0),
	m_TxQueue (TRUE),
	m_RxQueue (TRUE),
	m_ReassemblyQueue (&m_RxQueue, TCP_CONFIG_WINDOW_SCALED),
	m_bRetransmit (FALSE),
	m_bSendSYN (FALSE),
	m_bFINQueued (FALSE),
	m_bFINSent (FALSE),
	m_bFINReceived (FALSE),
	m_nRetransmissionCount (0),
	m_bTimedOut (FALSE),
	m_pTimer (CTimer::Get ()),
	m_nSND_WND (TCP_CONFIG_WINDOW),
	m_nSND_UP (0),
	m_nRCV_NXT (0),
	m_nRCV_WND (TCP_CONFIG_WINDOW),
	m_nIRS (0),
	m_bWindowScale (FALSE),
	m_nSndScale (0),
	m_nRcvScale (0),
	m_nRcvLimit (TCP_CONFIG_WINDOW),
	m_nRcvAdvEdge (0),
	m_nAckPending (0),
	m_nAckPendingTicks (0),
	m_nLastRxTicks (0),
	m_nRxSegments (0),
	m_nRxUnacceptable (0),
	m_nSND_MSS (536),	// RFC 1122 section 4.2.2.6
	m_nIW (4 * m_nSND_MSS),
	m_nCWND (m_nIW),
	m_nSSThresh (TCP_MAX_WINDOW),
	m_nDupAckCount (0),
	m_bFastRecovery (FALSE),
	m_nLastSendTicks (0),
	m_nReceiveTimeout (0),
	m_nSendTimeout (0)
{
	m_nMSS = m_nSND_MSS;

	s_nConnections++;

	for (unsigned nTimer = TCPTimerUser; nTimer < TCPTimerUnknown; nTimer++)
	{
		m_hTimer[nTimer] = 0;
	}

	m_nISS = CalculateISN ();
	m_RTOCalculator.Initialize (m_nISS, TCP_MAX_WINDOW, m_nSND_MSS);

	m_nSND_UNA = m_nISS;
	m_nSND_NXT = m_nISS+1;

	if (SendSegment (TCP_FLAG_SYN, m_nISS))
	{
		m_RTOCalculator.SegmentSent (m_nISS);
		NEW_STATE (TCPStateSynSent);
		m_nRetransmissionCount = MAX_SYN_RETRANSMISSIONS;
		StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());
	}
}

CTCPConnection::CTCPConnection (CNetConfig	*pNetConfig,
				CNetworkLayer	*pNetworkLayer,
				u16		 nOwnPort)
:	CNetConnection (pNetConfig, pNetworkLayer, nOwnPort, IPPROTO_TCP),
	m_bActiveOpen (FALSE),
	m_State (TCPStateListen),
	m_nErrno (0),
	m_TxQueue (TRUE),
	m_RxQueue (TRUE),
	m_ReassemblyQueue (&m_RxQueue, TCP_CONFIG_WINDOW_SCALED),
	m_bRetransmit (FALSE),
	m_bSendSYN (FALSE),
	m_bFINQueued (FALSE),
	m_bFINSent (FALSE),
	m_bFINReceived (FALSE),
	m_nRetransmissionCount (0),
	m_bTimedOut (FALSE),
	m_pTimer (CTimer::Get ()),
	m_nSND_WND (TCP_CONFIG_WINDOW),
	m_nSND_UP (0),
	m_nRCV_NXT (0),
	m_nRCV_WND (TCP_CONFIG_WINDOW),
	m_nIRS (0),
	m_bWindowScale (FALSE),
	m_nSndScale (0),
	m_nRcvScale (0),
	m_nRcvLimit (TCP_CONFIG_WINDOW),
	m_nRcvAdvEdge (0),
	m_nAckPending (0),
	m_nAckPendingTicks (0),
	m_nLastRxTicks (0),
	m_nRxSegments (0),
	m_nRxUnacceptable (0),
	m_nSND_MSS (536),	// RFC 1122 section 4.2.2.6
	m_nIW (4 * m_nSND_MSS),
	m_nCWND (m_nIW),
	m_nSSThresh (TCP_MAX_WINDOW),
	m_nDupAckCount (0),
	m_bFastRecovery (FALSE),
	m_nLastSendTicks (0),
	m_nReceiveTimeout (0),
	m_nSendTimeout (0)
{
	m_nMSS = m_nSND_MSS;

	s_nConnections++;

	for (unsigned nTimer = TCPTimerUser; nTimer < TCPTimerUnknown; nTimer++)
	{
		m_hTimer[nTimer] = 0;
	}
}

CTCPConnection::~CTCPConnection (void)
{
#ifdef TCP_DEBUG
	CLogger::Get ()->Write (FromTCP, LogDebug, "Delete TCB");
#endif

	assert (m_State == TCPStateClosed);

	for (unsigned nTimer = TCPTimerUser; nTimer < TCPTimerUnknown; nTimer++)
	{
		StopTimer (nTimer);
	}

	// ensure no task is waiting any more
	m_Event.Set ();
	m_TxEvent.Set ();

	assert (s_nConnections > 0);
	s_nConnections--;
}

const char *CTCPConnection::GetStateName (void) const
{
	return s_pStateName[m_State];
}

int CTCPConnection::Connect (void)
{
	if (m_nErrno < 0)
	{
		return m_nErrno;
	}

	switch (m_State)
	{
	case TCPStateSynSent:
	case TCPStateSynReceived:
		m_Event.Clear ();
		m_Event.Wait ();
		break;

	case TCPStateEstablished:
		break;

	case TCPStateListen:
	case TCPStateFinWait1:
	case TCPStateFinWait2:
	case TCPStateCloseWait:
	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		UNEXPECTED_STATE ();
		// fall through

	case TCPStateClosed:
		return -NET_ERROR_INVALID_VALUE;
	}

	return m_nErrno;
}

int CTCPConnection::Accept (CIPAddress *pForeignIP, u16 *pForeignPort)
{
	if (m_nErrno < 0)
	{
		return m_nErrno;
	}

	switch (m_State)
	{
	case TCPStateSynSent:
		UNEXPECTED_STATE ();
		// fall through

	case TCPStateClosed:
	case TCPStateFinWait1:
	case TCPStateFinWait2:
	case TCPStateCloseWait:
	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		return -NET_ERROR_CONNECTION_RESET;

	case TCPStateListen:
		m_Event.Clear ();
		m_Event.Wait ();
		break;

	case TCPStateSynReceived:
	case TCPStateEstablished:
		break;
	}

	// Onyx: a peer gone (RST) between its SYN and the wake-up (a port scan: connect, then
	// close at once) leaves the connection without a foreign address -- CIPAddress::Set
	// asserted and the whole machine halted. That peer is simply not accepted.
	if (m_nErrno < 0)
	{
		return m_nErrno;
	}
	if (!m_ForeignIP.IsSet ())
	{
		return -NET_ERROR_CONNECTION_RESET;
	}

	assert (pForeignIP != 0);
	pForeignIP->Set (m_ForeignIP);

	assert (pForeignPort != 0);
	*pForeignPort = m_nForeignPort;

	return m_nErrno;
}

int CTCPConnection::Close (void)
{
	switch (m_State)
	{
	case TCPStateClosed:
		return -NET_ERROR_INVALID_VALUE;

	case TCPStateListen:
	case TCPStateSynSent:
		StopTimer (TCPTimerRetransmission);
		NEW_STATE (TCPStateClosed);
		break;

	case TCPStateSynReceived:
	case TCPStateEstablished:
		assert (!m_bFINQueued);
		m_StateAfterFIN = TCPStateFinWait1;
		m_nRetransmissionCount = MAX_RETRANSMISSIONS;
		m_bFINQueued = TRUE;
		break;
		
	case TCPStateFinWait1:
	case TCPStateFinWait2:
		break;

	case TCPStateCloseWait:
		assert (!m_bFINQueued);
		m_StateAfterFIN = TCPStateLastAck;	// RFC 1122 section 4.2.2.20 (a)
		m_nRetransmissionCount = MAX_RETRANSMISSIONS;
		m_bFINQueued = TRUE;
		break;

	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		return -NET_ERROR_CONNECTION_RESET;
	}

	if (m_nErrno < 0)
	{
		return m_nErrno;
	}
	
	return 0;
}

int CTCPConnection::Send (CNetBuffer *pNetBuffer, int nFlags)
{
	if (nFlags & ~(MSG_DONTWAIT | MSG_MORE))
	{
		return -NET_ERROR_INVALID_VALUE;
	}

	if (m_nErrno < 0)
	{
		return m_nErrno;
	}
	
	switch (m_State)
	{
	case TCPStateClosed:
	case TCPStateListen:
	case TCPStateFinWait1:
	case TCPStateFinWait2:
	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		return -NET_ERROR_CONNECTION_RESET;

	case TCPStateSynSent:
	case TCPStateSynReceived:
	case TCPStateEstablished:
	case TCPStateCloseWait:
		break;
	}
	
	if (   !(nFlags & MSG_DONTWAIT)
	    && m_TxQueue.GetBytesQueued () >= TCP_CONFIG_TX_THRESHOLD)
	{
		m_TxEvent.Clear ();

		if (m_nSendTimeout == 0)
		{
			m_TxEvent.Wait ();
		}
		else
		{
			if (m_TxEvent.WaitWithTimeout (m_nSendTimeout))
			{
				return -NET_ERROR_WOULD_BLOCK;
			}
		}

		if (m_nErrno < 0)
		{
			return m_nErrno;
		}
	}

	assert (pNetBuffer != 0);
	pNetBuffer->SetPrivateData (&nFlags, sizeof nFlags);

	int nResult = pNetBuffer->GetLength ();

	m_TxQueue.Enqueue (pNetBuffer);

	return nResult;
}

int CTCPConnection::Receive (CNetBuffer **ppNetBuffer, int nFlags)
{
	if (nFlags & ~(MSG_DONTWAIT | MSG_MORE))
	{
		return -NET_ERROR_INVALID_VALUE;
	}

	if (m_nErrno < 0)
	{
		return m_nErrno;
	}

	assert (ppNetBuffer != 0);
	while ((*ppNetBuffer = m_RxQueue.Dequeue ()) == 0)
	{
		switch (m_State)
		{
		case TCPStateClosed:
		case TCPStateListen:
		case TCPStateFinWait1:
		case TCPStateFinWait2:
		case TCPStateCloseWait:
		case TCPStateClosing:
		case TCPStateLastAck:
		case TCPStateTimeWait:
			return -NET_ERROR_CONNECTION_RESET;

		case TCPStateSynSent:
		case TCPStateSynReceived:
		case TCPStateEstablished:
			break;
		}

		if (nFlags & MSG_DONTWAIT)
		{
			return 0;
		}

		m_Event.Clear ();

		if (m_nReceiveTimeout == 0)
		{
			m_Event.Wait ();
		}
		else
		{
			if (m_Event.WaitWithTimeout (m_nReceiveTimeout))
			{
				return -NET_ERROR_WOULD_BLOCK;
			}
		}

		if (m_nErrno < 0)
		{
			return m_nErrno;
		}
	}

	size_t nLength = (*ppNetBuffer)->GetLength ();
	assert (nLength <= FRAME_BUFFER_SIZE);

	// Onyx: the window follows the receive queue (ReceiveWindow). The reader has just made
	// room: once that opens the window by a quarter of its size over what the peer was last
	// told, tell it (a window update) -- a peer stopped by a closed window starts again.
	if (   m_State == TCPStateEstablished
	    || m_State == TCPStateFinWait1
	    || m_State == TCPStateFinWait2)
	{
		u32 nAdvertised = m_nRcvAdvEdge - m_nRCV_NXT;
		u32 nWindow = ReceiveWindow ();
		if (   nWindow > nAdvertised
		    && nWindow - nAdvertised >= m_nRcvLimit / 4)
		{
			SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
		}
	}

	return nLength;
}

int CTCPConnection::SendTo (CNetBuffer *pNetBuffer, int nFlags,
			    const CIPAddress &rForeignIP, u16 nForeignPort)
{
	// ignore rForeignIP and nForeignPort
	return Send (pNetBuffer, nFlags);
}

int CTCPConnection::ReceiveFrom (CNetBuffer **ppNetBuffer, int nFlags, CIPAddress *pForeignIP, u16 *pForeignPort)
{
	int nResult = Receive (ppNetBuffer, nFlags);
	if (nResult <= 0)
	{
		return nResult;
	}

	if (   pForeignIP != 0
	    && pForeignPort != 0)
	{
		pForeignIP->Set (m_ForeignIP);
		*pForeignPort = m_nForeignPort;
	}

	return nResult;
}

int CTCPConnection::SetOptionReceiveTimeout (unsigned nMicroSeconds)
{
	m_nReceiveTimeout = nMicroSeconds;

	return 0;
}

int CTCPConnection::SetOptionSendTimeout (unsigned nMicroSeconds)
{
	m_nSendTimeout = nMicroSeconds;

	return 0;
}

int CTCPConnection::SetOptionBroadcast (boolean bAllowed)
{
	return 0;
}

int CTCPConnection::SetOptionAddMembership (const CIPAddress &rGroupAddress)
{
	return -NET_ERROR_OPERATION_NOT_SUPPORTED;
}

int CTCPConnection::SetOptionDropMembership (const CIPAddress &rGroupAddress)
{
	return -NET_ERROR_OPERATION_NOT_SUPPORTED;
}

boolean CTCPConnection::IsConnected (void) const
{
	return     m_State > TCPStateSynSent
		&& m_State != TCPStateTimeWait;
}

boolean CTCPConnection::IsTerminated (void) const
{
	return m_State == TCPStateClosed;
}

void CTCPConnection::Process (void)
{
	if (m_bTimedOut)
	{
		m_nErrno = -NET_ERROR_CONNECTION_TIMED_OUT;
		NEW_STATE (TCPStateClosed);
		m_Event.Set ();
		m_TxEvent.Set ();
		return;
	}

	// Onyx: a delayed acknowledgement that no second segment came to send
	if (   m_nAckPending != 0
	    && m_pTimer->GetTicks () - m_nAckPendingTicks >= 2
	    && (   m_State == TCPStateEstablished
		|| m_State == TCPStateFinWait1
		|| m_State == TCPStateFinWait2))
	{
		SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
	}

	switch (m_State)
	{
	case TCPStateClosed:
	case TCPStateListen:
	case TCPStateFinWait2:
	case TCPStateTimeWait:
		return;

	case TCPStateSynSent:
	case TCPStateSynReceived:
		if (m_bSendSYN)
		{
			m_bSendSYN = FALSE;
			if (m_State == TCPStateSynSent)
			{
				SendSegment (TCP_FLAG_SYN, m_nISS);
			}
			else
			{
				SendSegment (TCP_FLAG_SYN | TCP_FLAG_ACK, m_nISS, m_nRCV_NXT);
			}
			m_RTOCalculator.SegmentSent (m_nISS);
			StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());
		}
		return;
		
	case TCPStateEstablished:
	case TCPStateFinWait1:
	case TCPStateCloseWait:
	case TCPStateClosing:
	case TCPStateLastAck:
		if (   m_TxQueue.IsEmpty ()
		    && m_bFINQueued)
		{
			if (!m_bFINSent)
			{
				m_nSND_NXT++;
				m_bFINSent = TRUE;
			}
			SendSegment (TCP_FLAG_FIN | TCP_FLAG_ACK, m_nSND_NXT-1, m_nRCV_NXT);
			m_RTOCalculator.SegmentSent (m_nSND_NXT-1);
			NEW_STATE (m_StateAfterFIN);
			m_bFINQueued = FALSE;
			StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());
		}
		break;
	}

	// pacing transmit
	if (   (   m_State == TCPStateEstablished
		|| m_State == TCPStateCloseWait)
	    && m_TxQueue.GetBytesQueued () < TCP_CONFIG_TX_THRESHOLD)
	{
		m_TxEvent.Set ();
	}

	if (m_bRetransmit)
	{
#ifdef TCP_DEBUG
		CLogger::Get ()->Write (FromTCP, LogDebug, "Retransmission (nxt %u, una %u)", m_nSND_NXT-m_nISS, m_nSND_UNA-m_nISS);
#endif
		m_bRetransmit = FALSE;
		if (onyx_tcp_trace)
		{
			CString IP;
			m_ForeignIP.Format (&IP);
			CLogger::Get ()->Write (FromTCP, LogWarning, "timeout: %u <-> %s:%u, rto %u, una %u nxt %u (%u in flight, %u queued), rcv.nxt %u wnd %u, snd.wnd %u cwnd %u; the peer: %u segments since (%u refused), the last %u ticks ago",
				(unsigned) m_nOwnPort, (const char *) IP, (unsigned) m_nForeignPort, m_RTOCalculator.GetRTO (), m_nSND_UNA - m_nISS, m_nSND_NXT - m_nISS,
				m_nSND_NXT - m_nSND_UNA, (unsigned) m_TxQueue.GetBytesQueued (), m_nRCV_NXT - m_nIRS, m_nRCV_WND, m_nSND_WND, m_nCWND,
				m_nRxSegments, m_nRxUnacceptable, m_pTimer->GetTicks () - m_nLastRxTicks);
			m_nRxSegments = m_nRxUnacceptable = 0;
		}
		onyx_tcp_rto_count++;
		if (m_RTOCalculator.GetRTO () > onyx_tcp_rto_max)
		{
			onyx_tcp_rto_max = m_RTOCalculator.GetRTO ();
		}

		// congestion control (RFC 5681 section 3.1. equation (4))
		m_nSSThresh = max (FLIGHT_SIZE / 2, 2 * m_nSND_MSS);
		m_nCWND = m_nSND_MSS;
		m_bFastRecovery = FALSE;
		m_nDupAckCount = 0;

		ResendSegment ();
	}

	// Restart after idle (RFC 5681 section 4.1)
	// If connection has been idle for longer than RTO (no outstanding data and no ACKs),
	// reduce cwnd to IW to avoid bursts.
	if (   (m_pTimer->GetTicks () - m_nLastSendTicks) > m_RTOCalculator.GetRTO ()
	    && FLIGHT_SIZE == 0)
	{
		m_nCWND = min (m_nIW, m_nCWND);
	}

	while (SendNewSegment ())
	{
		// just loop
	}
}

boolean CTCPConnection::SendNewSegment (u32 nAdditionalCWND)
{
	const CNetBuffer *pNetBuffer;
	if ((pNetBuffer = m_TxQueue.Peek ()) != 0)
	{
		int nWindowLeft = min (m_nCWND + nAdditionalCWND, m_nSND_WND) - FLIGHT_SIZE;
		u32 nLength = pNetBuffer->GetLength ();
		if (nWindowLeft < (int) nLength)
		{
			return FALSE;
		}

#ifdef TCP_DEBUG
		CLogger::Get ()->Write (FromTCP, LogDebug, "Transfering %u bytes into TX buffer", nLength);
#endif

		unsigned nFlags = TCP_FLAG_ACK;
		const int *pFlags = (const int *) pNetBuffer->GetPrivateData ();
		assert (pFlags != 0);
		if (!(*pFlags & MSG_MORE))
		{
			nFlags |= TCP_FLAG_PUSH;
		}

		CNetBuffer *pNetBuffer2 = new CNetBuffer (*pNetBuffer);
		assert (pNetBuffer2 != 0);

		SendSegment (nFlags, m_nSND_NXT, m_nRCV_NXT, pNetBuffer2);
		m_RTOCalculator.SegmentSent (m_nSND_NXT, nLength);
		m_nSND_NXT += nLength;
		StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());

		m_nLastSendTicks = m_pTimer->GetTicks ();

		m_TxQueue.MoveOn ();
	}
	else
	{
		return FALSE;
	}

	return TRUE;
}

int CTCPConnection::PacketReceived (CNetBuffer	*pPacket,
				    CIPAddress	&rSenderIP,
				    CIPAddress	&rReceiverIP,
				    int		 nProtocol)
{
	if (nProtocol != IPPROTO_TCP)
	{
		return 0;
	}

	assert (pPacket != 0);
	size_t nLength = pPacket->GetLength ();
	if (nLength < sizeof (TTCPHeader))
	{
		delete pPacket;

		return -1;
	}

	TTCPHeader *pHeader = (TTCPHeader *) pPacket->GetPtr ();
	assert (pHeader != 0);

	if (m_nOwnPort != be2le16 (pHeader->nDestPort))
	{
		return 0;
	}
	
	if (m_State != TCPStateListen)
	{
		if (   m_ForeignIP != rSenderIP
		    || m_nForeignPort != be2le16 (pHeader->nSourcePort))
		{
			return 0;
		}
	}
	else
	{
		if (!(pHeader->nDataOffsetFlags & TCP_FLAG_SYN))
		{
			return 0;
		}

		m_Checksum.SetDestinationAddress (rSenderIP);
	}

	if (m_Checksum.Calculate (pHeader, nLength) != CHECKSUM_OK)
	{
		return 0;
	}

	u16 nFlags = pHeader->nDataOffsetFlags;
	u32 nDataOffset = TCP_DATA_OFFSET (pHeader->nDataOffsetFlags)*4;
	u32 nDataLength = nLength-nDataOffset;

	// Current Segment Variables
	u32 nSEG_SEQ = be2le32 (pHeader->nSequenceNumber);
	u32 nSEG_ACK = be2le32 (pHeader->nAcknowledgmentNumber);

	u32 nSEG_LEN = nDataLength;
	if (nFlags & TCP_FLAG_SYN)
	{
		nSEG_LEN++;
	}
	if (nFlags & TCP_FLAG_FIN)
	{
		nSEG_LEN++;
	}
	
	u32 nSEG_WND = be2le16 (pHeader->nWindow);
	//u16 nSEG_UP  = be2le16 (pHeader->nUrgentPointer);
	//u32 nSEG_PRC;	// segment precedence value

	m_nLastRxTicks = m_pTimer->GetTicks ();	// Onyx (onyx_tcp_trace)
	m_nRxSegments++;

	ScanOptions (pHeader);

	if (!(nFlags & TCP_FLAG_SYN))		// Onyx: RFC 7323 section 2.2 (a SYN's window is never scaled)
	{
		nSEG_WND <<= m_nSndScale;
	}

#ifdef TCP_DEBUG
	CLogger::Get ()->Write (FromTCP, LogDebug,
				"rx %c%c%c%c%c%c, seq %u, ack %u, win %u, len %u",
				nFlags & TCP_FLAG_URGENT ? 'U' : '-',
				nFlags & TCP_FLAG_ACK    ? 'A' : '-',
				nFlags & TCP_FLAG_PUSH   ? 'P' : '-',
				nFlags & TCP_FLAG_RESET  ? 'R' : '-',
				nFlags & TCP_FLAG_SYN    ? 'S' : '-',
				nFlags & TCP_FLAG_FIN    ? 'F' : '-',
				nSEG_SEQ-m_nIRS,
				nFlags & TCP_FLAG_ACK ? nSEG_ACK-m_nISS : 0,
				nSEG_WND,
				nDataLength);

	DumpStatus ();
#endif

	pPacket->RemoveHeader (nDataOffset);

	boolean bAcceptable = FALSE;

	// RFC 793 section 3.9 "SEGMENT ARRIVES"
	switch (m_State)
	{
	case TCPStateClosed:
		if (nFlags & TCP_FLAG_RESET)
		{
			// ignore
		}
		else if (!(nFlags & TCP_FLAG_ACK))
		{
			m_ForeignIP.Set (rSenderIP);
			m_nForeignPort = be2le16 (pHeader->nSourcePort);
			m_Checksum.SetDestinationAddress (rSenderIP);

			SendSegment (TCP_FLAG_RESET | TCP_FLAG_ACK, 0, nSEG_SEQ+nSEG_LEN);
		}
		else
		{
			m_ForeignIP.Set (rSenderIP);
			m_nForeignPort = be2le16 (pHeader->nSourcePort);
			m_Checksum.SetDestinationAddress (rSenderIP);

			SendSegment (TCP_FLAG_RESET, nSEG_ACK);
		}
		break;

	case TCPStateListen:
		if (nFlags & TCP_FLAG_RESET)
		{
			// ignore
		}
		else if (nFlags & TCP_FLAG_ACK)
		{
			m_ForeignIP.Set (rSenderIP);
			m_nForeignPort = be2le16 (pHeader->nSourcePort);
			m_Checksum.SetDestinationAddress (rSenderIP);

			SendSegment (TCP_FLAG_RESET, nSEG_ACK);
		}
		else if (nFlags & TCP_FLAG_SYN)
		{
			if (s_nConnections >= TCP_MAX_CONNECTIONS)
			{
				m_ForeignIP.Set (rSenderIP);
				m_nForeignPort = be2le16 (pHeader->nSourcePort);
				m_Checksum.SetDestinationAddress (rSenderIP);

				SendSegment (TCP_FLAG_RESET | TCP_FLAG_ACK, 0, nSEG_SEQ+nSEG_LEN);

				break;
			}

			m_nRCV_NXT = nSEG_SEQ+1;
			m_nIRS = nSEG_SEQ;

			m_nSND_WND = nSEG_WND;
			m_nSND_WL1 = nSEG_SEQ;
			m_nSND_WL2 = nSEG_ACK;
	
			assert (nSEG_LEN > 0);

			if (nDataLength > 0)
			{
				m_RxQueue.Enqueue (pPacket);
				pPacket = 0;
			}

			m_nISS = CalculateISN ();
			m_RTOCalculator.Initialize (m_nISS, TCP_MAX_WINDOW, m_nSND_MSS);

			m_ForeignIP.Set (rSenderIP);
			m_nForeignPort = be2le16 (pHeader->nSourcePort);
			m_Checksum.SetDestinationAddress (rSenderIP);

			SendSegment (TCP_FLAG_SYN | TCP_FLAG_ACK, m_nISS, m_nRCV_NXT);
			m_RTOCalculator.SegmentSent (m_nISS);

			m_nSND_NXT = m_nISS+1;
			m_nSND_UNA = m_nISS;

			NEW_STATE (TCPStateSynReceived);

			m_Event.Set ();
		}
		break;

	case TCPStateSynSent:
		if (nFlags & TCP_FLAG_ACK)
		{
			if (!bwh (m_nISS, nSEG_ACK, m_nSND_NXT))
			{
				if (!(nFlags & TCP_FLAG_RESET))
				{
					SendSegment (TCP_FLAG_RESET, nSEG_ACK);
				}

				delete pPacket;

				return 1;
			}
			else if (bwlh (m_nSND_UNA, nSEG_ACK, m_nSND_NXT))
			{
				bAcceptable = TRUE;
			}
		}

		if (nFlags & TCP_FLAG_RESET)
		{
			if (bAcceptable)
			{
				StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
				NEW_STATE (TCPStateClosed);
				m_bSendSYN = FALSE;
				m_nErrno = -NET_ERROR_CONNECTION_REFUSED;

				m_Event.Set ();
			}
			
			break;
		}
		
		if (   (nFlags & TCP_FLAG_ACK)
		    && !bAcceptable)
		{
			break;
		}

		if (nFlags & TCP_FLAG_SYN)
		{
			m_nRCV_NXT = nSEG_SEQ+1;
			m_nIRS = nSEG_SEQ;

			if (nFlags & TCP_FLAG_ACK)
			{
				m_RTOCalculator.SegmentAcknowledged (m_nSND_UNA);

				if (nSEG_ACK-m_nSND_UNA > 1)
				{
					m_TxQueue.Flush (nSEG_ACK-m_nSND_UNA-1);
				}

				m_nSND_UNA = nSEG_ACK;
			}

			if (gt (m_nSND_UNA, m_nISS))
			{
				NEW_STATE (TCPStateEstablished);
				m_bSendSYN = FALSE;

				StopTimer (TCPTimerRetransmission);

				// next transmission starts with this count
				m_nRetransmissionCount = MAX_RETRANSMISSIONS;

				m_Event.Set ();

				// RFC 1122 section 4.2.2.20 (c)
				m_nSND_WND = nSEG_WND;
				m_nSND_WL1 = nSEG_SEQ;
				m_nSND_WL2 = nSEG_ACK;
	
				SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
				
				if (   (nFlags & TCP_FLAG_FIN)		// other controls?
				    || nDataLength > 0)
				{
					goto StepSix;
				}

				break;
			}
			else
			{
				NEW_STATE (TCPStateSynReceived);
				m_bSendSYN = FALSE;
				SendSegment (TCP_FLAG_SYN | TCP_FLAG_ACK, m_nISS, m_nRCV_NXT);
				m_RTOCalculator.SegmentSent (m_nISS);
				m_nRetransmissionCount = MAX_SYN_RETRANSMISSIONS;
				StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());

				if (   (nFlags & TCP_FLAG_FIN)		// other controls?
				    || nDataLength > 0)
				{
					if (nFlags & TCP_FLAG_FIN)
					{
						SendSegment (TCP_FLAG_RESET, m_nSND_NXT);
						StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
						NEW_STATE (TCPStateClosed);
						m_nErrno = -NET_ERROR_PROTOCOL_ERROR;
						m_Event.Set ();
					}

					if (nDataLength > 0)
					{
						m_RxQueue.Enqueue (pPacket);
						pPacket = 0;
					}

					break;
				}
			}
		}
		break;

	case TCPStateSynReceived:
	case TCPStateEstablished:
	case TCPStateFinWait1:
	case TCPStateFinWait2:
	case TCPStateCloseWait:
	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		// step 1 ( check sequence number)
		if (m_nRCV_WND > 0)
		{
			if (nSEG_LEN == 0)
			{
				if (bwl (m_nRCV_NXT, nSEG_SEQ, m_nRCV_NXT+m_nRCV_WND))
				{
					bAcceptable = TRUE;
				}
			}
			else
			{
				if (   bwl (m_nRCV_NXT, nSEG_SEQ, m_nRCV_NXT+m_nRCV_WND)
				    || bwl (m_nRCV_NXT, nSEG_SEQ+nSEG_LEN-1, m_nRCV_NXT+m_nRCV_WND))
				{
					bAcceptable = TRUE;
				}
			}
		}
		else
		{
			if (nSEG_LEN == 0)
			{
				if (nSEG_SEQ == m_nRCV_NXT)
				{
					bAcceptable = TRUE;
				}
			}
		}

		if (   !bAcceptable
		    && m_State != TCPStateSynReceived)
		{
			m_nRxUnacceptable++;
			SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
			break;
		}

		// step 2 (check RST bit)
		if (nFlags & TCP_FLAG_RESET)
		{
			switch (m_State)
			{
			case TCPStateSynReceived:
				m_TxQueue.Flush ();
				if (!m_bActiveOpen)
				{
					NEW_STATE (TCPStateListen);

					delete pPacket;

					return 1;
				}
				else
				{
					m_nErrno = -NET_ERROR_CONNECTION_RESET;
					StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
					NEW_STATE (TCPStateClosed);
					m_Event.Set ();

					delete pPacket;

					return 1;
					
				}
				break;

			case TCPStateEstablished:
			case TCPStateFinWait1:
			case TCPStateFinWait2:
			case TCPStateCloseWait:
				m_nErrno = -NET_ERROR_CONNECTION_RESET;
				m_TxQueue.Flush ();
				m_RxQueue.Flush ();
				StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
				NEW_STATE (TCPStateClosed);
				m_Event.Set ();
				m_TxEvent.Set ();			// Onyx: a sender waiting for room sees the reset

				delete pPacket;

				return 1;

			case TCPStateClosing:
			case TCPStateLastAck:
			case TCPStateTimeWait:
				StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
				NEW_STATE (TCPStateClosed);
				m_Event.Set ();

				delete pPacket;

				return 1;

			default:
				UNEXPECTED_STATE ();

				delete pPacket;

				return 1;
			}
		}

		// step 3 (check security and precedence, not supported)
		
		// step 4 (check SYN bit)
		if (nFlags & TCP_FLAG_SYN)
		{
			// RFC 1122 section 4.2.2.20 (e)
			if (   m_State == TCPStateSynReceived
			    && !m_bActiveOpen)
			{
				NEW_STATE (TCPStateListen);

				delete pPacket;

				return 1;
			}
			
			SendSegment (TCP_FLAG_RESET, m_nSND_NXT);
			m_nErrno = -NET_ERROR_PROTOCOL_ERROR;
			m_TxQueue.Flush ();
			m_RxQueue.Flush ();
			StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
			NEW_STATE (TCPStateClosed);
			m_Event.Set ();
			m_TxEvent.Set ();			// Onyx: as for a RST

			delete pPacket;

			return 1;
		}

		// step 5 (check ACK field)
		if (!(nFlags & TCP_FLAG_ACK))
		{
			delete pPacket;

			return 1;
		}

		switch (m_State)
		{
		case TCPStateSynReceived:
			if (bwlh (m_nSND_UNA, nSEG_ACK, m_nSND_NXT))
			{
				// RFC 1122 section 4.2.2.20 (f)
				m_nSND_WND = nSEG_WND;
				m_nSND_WL1 = nSEG_SEQ;
				m_nSND_WL2 = nSEG_ACK;

				m_RTOCalculator.SegmentAcknowledged (m_nSND_UNA);

				m_nSND_UNA = nSEG_ACK;		// got ACK for SYN

				NEW_STATE (TCPStateEstablished);

				// next transmission starts with this count
				m_nRetransmissionCount = MAX_RETRANSMISSIONS;
			}
			else
			{
				SendSegment (TCP_FLAG_RESET, nSEG_ACK);
			}
			break;

		case TCPStateEstablished:
		case TCPStateFinWait1:
		case TCPStateFinWait2:
		case TCPStateCloseWait:
		case TCPStateClosing:
#ifdef TCP_DEBUG
			CLogger::Get ()->Write (FromTCP, LogDebug,
						"Dups %u, FastRecover %c, Recover %u",
						m_nDupAckCount,
						m_bFastRecovery ? 'y' : 'n',
						m_bFastRecovery ? m_nRecover-m_nISS : 0);
#endif
			if (bwh (m_nSND_UNA, nSEG_ACK, m_nSND_NXT))
			{
				m_RTOCalculator.SegmentAcknowledged (m_nSND_UNA);

				unsigned nBytesAck = nSEG_ACK-m_nSND_UNA;
				m_nSND_UNA = nSEG_ACK;

				if (nSEG_ACK == m_nSND_NXT)	// all segments are acknowledged
				{
					StopTimer (TCPTimerRetransmission);

					// next transmission starts with this count
					m_nRetransmissionCount = MAX_RETRANSMISSIONS;
				}

				if (   m_State == TCPStateFinWait1
				    || m_State == TCPStateClosing)
				{
					nBytesAck--;		// acknowledged FIN does not count
					m_bFINQueued = FALSE;
				}

				if (nBytesAck > 0)
				{
					m_TxQueue.Flush (nBytesAck);

					if (FLIGHT_SIZE)
					{
						m_nRetransmissionCount = MAX_RETRANSMISSIONS;

						StartTimer (TCPTimerRetransmission,
							    m_RTOCalculator.GetRTO ());
					}
				}

				// congestion control
				m_nDupAckCount = 0;
				if (m_bFastRecovery)
				{
					// RFC 5681 recommends NewReno (RFC 6582)
					if (ge (nSEG_ACK, m_nRecover))
					{
						// ACK'ed all data outstanding,
						// when fast recovery began
						m_bFastRecovery = FALSE;
						m_nCWND = max (m_nSSThresh, m_nSND_MSS);
					}
					else
					{
						// Partial ACK: still recovering
						ResendSegment ();

						m_nCWND = max (m_nSSThresh + 3*m_nSND_MSS - nBytesAck,
							       m_nSND_MSS);
					}
				}
				else
				{
					// Not in fast recovery: normal cwnd growth
					if (m_nCWND < m_nSSThresh)
					{
						// Slow Start (Section 3.1):
						// increase by at most SMSS per ACK
						m_nCWND += min (nBytesAck, m_nSND_MSS);
					}
					else
					{
						// Congestion Avoidance (Section 3.1):
						// increase by ~1 SMSS per RTT
						m_nCWND += max ((m_nSND_MSS * m_nSND_MSS) / m_nCWND, 1);
					}
				}

				// update send window
				if (   lt (m_nSND_WL1, nSEG_SEQ)
				    || (   m_nSND_WL1 == nSEG_SEQ
				        && le (m_nSND_WL2, nSEG_ACK)))
				{
					m_nSND_WND = nSEG_WND;
					m_nSND_WL1 = nSEG_SEQ;
					m_nSND_WL2 = nSEG_ACK;
				}
			}
			else if (le (nSEG_ACK, m_nSND_UNA))	// RFC 1122 section 4.2.2.20 (g)
			{
				// Onyx: only a real duplicate ACK counts (RFC 5681 section 2): no data,
				// no SYN / FIN (nSEG_LEN), the ACK number SND.UNA, the window unchanged,
				// and data outstanding. The peer's own data segments (a remote desktop
				// client's input messages) and pure window updates used to count too:
				// three in a row started a spurious fast retransmit + fast recovery.
				if (   nSEG_LEN == 0
				    && nSEG_ACK == m_nSND_UNA
				    && nSEG_WND == m_nSND_WND
				    && FLIGHT_SIZE > 0)
				{
					OnDuplicateAck ();
				}

				// RFC 1122 section 4.2.2.20 (g)
				if (bwlh (m_nSND_UNA, nSEG_ACK, m_nSND_NXT))
				{
					// ... but update send window
					if (   lt (m_nSND_WL1, nSEG_SEQ)
					    || (   m_nSND_WL1 == nSEG_SEQ
						&& le (m_nSND_WL2, nSEG_ACK)))
					{
						m_nSND_WND = nSEG_WND;
						m_nSND_WL1 = nSEG_SEQ;
						m_nSND_WL2 = nSEG_ACK;
					}
				}
			}
			else if (gt (nSEG_ACK, m_nSND_NXT))
			{
				SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);

				delete pPacket;

				return 1;
			}
			
			switch (m_State)
			{
			case TCPStateEstablished:
			case TCPStateCloseWait:
				break;

			case TCPStateFinWait1:
				if (nSEG_ACK == m_nSND_NXT)	// if our FIN is now acknowledged
				{
					m_RTOCalculator.SegmentAcknowledged (m_nSND_UNA);

					m_bFINQueued = FALSE;
					StopTimer (TCPTimerRetransmission);
					NEW_STATE (TCPStateFinWait2);
					StartTimer (TCPTimerTimeWait, HZ_FIN_TIMEOUT);
				}
				else
				{
					break;
				}
				// fall through

			case TCPStateFinWait2:
				if (m_TxQueue.IsEmpty ())
				{
					m_Event.Set ();
				}
				break;
				
			case TCPStateClosing:
				if (nSEG_ACK == m_nSND_NXT)	// if our FIN is now acknowledged
				{
					m_RTOCalculator.SegmentAcknowledged (m_nSND_UNA);

					m_bFINQueued = FALSE;
					StopTimer (TCPTimerRetransmission);
					NEW_STATE (TCPStateTimeWait);
					StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);
				}
				break;

			default:
				UNEXPECTED_STATE ();
				break;
			}
			break;
			
		case TCPStateLastAck:
			if (nSEG_ACK == m_nSND_NXT)	// if our FIN is now acknowledged
			{
				m_bFINQueued = FALSE;
				StopTimer (TCPTimerRetransmission);	// Onyx: see TimerHandler
				NEW_STATE (TCPStateClosed);
				m_Event.Set ();

				delete pPacket;

				return 1;
			}
			break;

		case TCPStateTimeWait:
			if (nSEG_ACK == m_nSND_NXT)	// if our FIN is now acknowledged
			{
				m_bFINQueued = FALSE;
				SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
				StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);
			}
			break;

		default:
			UNEXPECTED_STATE ();
			break;
		}

		// step 6 (check URG bit, not supported)
	StepSix:

		// step 7 (process text segment)
		if (nSEG_LEN == 0)
		{
			delete pPacket;

			return 1;
		}
		
		switch (m_State)
		{
		case TCPStateEstablished:
		case TCPStateFinWait1:
		case TCPStateFinWait2:
			if (nSEG_SEQ == m_nRCV_NXT)
			{
				if (nDataLength > 0)
				{
					m_RxQueue.Enqueue (pPacket);
					pPacket = 0;

					m_nRCV_NXT += nDataLength;

					u32 nRCV_NXT = m_nRCV_NXT;
					m_nRCV_NXT = m_ReassemblyQueue.Dequeue (m_nRCV_NXT);

					// m_nRCV_WND should be adjusted here (section 3.7)

					// Onyx (onyx_tcp_ws & 2): delayed acknowledgements (RFC 1122 section
					// 4.2.3.2, RFC 5681 section 4.2). Every data segment was acknowledged
					// by a segment of its own: receiving 8 MB/s, the Pi sent 6000 frames a
					// second on the same radio, and its other connections' segments were
					// lost among them (an echo answered after 3 s during a download). One
					// acknowledgement for two full segments; at once for a short segment
					// (a request, the end of a burst), a PUSH, a hole filled; the odd
					// full segment is acknowledged by Process within 10 to 20 ms.
					if (   !(onyx_tcp_ws & 2)
					    || (nFlags & (TCP_FLAG_PUSH | TCP_FLAG_FIN))
					    || nDataLength < 1000
					    || m_nRCV_NXT != nRCV_NXT
					    || m_nAckPending + 1 >= (unsigned) onyx_tcp_ackn)
					{
						// following ACK could be piggybacked with data
						SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
					}
					else
					{
						if (m_nAckPending++ == 0)
						{
							m_nAckPendingTicks = m_pTimer->GetTicks ();
						}
					}

					if (   (nFlags & TCP_FLAG_PUSH)
					    || m_RxQueue.GetBytesQueued () >= TCP_CONFIG_RX_THRESHOLD)
					{
						m_Event.Set ();
					}
				}
			}
			else
			{
				SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);

				if (   nDataLength > 0
				    && m_ReassemblyQueue.Enqueue (nSEG_SEQ, pPacket))
				{
					pPacket = 0;
				}

				delete pPacket;

				return 1;
			}
			break;

		case TCPStateSynReceived:	// this state not in RFC 793
		case TCPStateCloseWait:
		case TCPStateClosing:
		case TCPStateLastAck:
		case TCPStateTimeWait:
			break;

		default:
			UNEXPECTED_STATE ();
			break;
		}

		// step 8 (check FIN bit)
		if (   m_State == TCPStateClosed
		    || m_State == TCPStateListen
		    || m_State == TCPStateSynSent)
		{
			delete pPacket;

			return 1;
		}
			
		if (!(nFlags & TCP_FLAG_FIN))
		{
			delete pPacket;

			return 1;
		}

		// connection is closing
		if (!m_bFINReceived)
		{
			m_nRCV_NXT++;
			m_bFINReceived = TRUE;
		}
		SendSegment (TCP_FLAG_ACK, m_nSND_NXT, m_nRCV_NXT);
		
		switch (m_State)
		{
		case TCPStateSynReceived:
		case TCPStateEstablished:
			NEW_STATE (TCPStateCloseWait);
			m_Event.Set ();
			break;

		case TCPStateFinWait1:
			if (nSEG_ACK == m_nSND_NXT)	// if our FIN is now acknowledged
			{
				m_bFINQueued = FALSE;
				StopTimer (TCPTimerRetransmission);
				StopTimer (TCPTimerUser);
				NEW_STATE (TCPStateTimeWait);
				StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);
			}
			else
			{
				NEW_STATE (TCPStateClosing);
			}
			break;

		case TCPStateFinWait2:
			StopTimer (TCPTimerRetransmission);
			StopTimer (TCPTimerUser);
			NEW_STATE (TCPStateTimeWait);
			StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);
			break;

		case TCPStateCloseWait:
		case TCPStateClosing:
		case TCPStateLastAck:
			break;
			
		case TCPStateTimeWait:
			StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);
			break;

		default:
			UNEXPECTED_STATE ();
			break;
		}
		break;
	}

	delete pPacket;

	return 1;
}

int CTCPConnection::NotificationReceived (TICMPNotificationType  Type,
					  CIPAddress		&rSenderIP,
					  CIPAddress		&rReceiverIP,
					  u16			 nSendPort,
					  u16			 nReceivePort,
					  int			 nProtocol)
{
	if (nProtocol != IPPROTO_TCP)
	{
		return 0;
	}

	if (m_State < TCPStateSynSent)
	{
		return 0;
	}

	if (   m_ForeignIP != rSenderIP
	    || m_nForeignPort != nSendPort)
	{
		return 0;
	}

	assert (m_pNetConfig != 0);
	if (   rReceiverIP != *m_pNetConfig->GetIPAddress ()
	    || m_nOwnPort != nReceivePort)
	{
		return 0;
	}

	m_nErrno =   Type == ICMPNotificationDestUnreach
		   ? -NET_ERROR_DESTINATION_UNREACHABLE
		   : -NET_ERROR_PROTOCOL_ERROR;

	StopTimer (TCPTimerRetransmission);
	NEW_STATE (TCPStateTimeWait);
	StartTimer (TCPTimerTimeWait, HZ_TIMEWAIT);

	m_Event.Set ();

	return 1;
}

CNetConnection::TStatus CTCPConnection::GetStatus (void) const
{
	TStatus Status = {FALSE, FALSE, FALSE, FALSE};

	switch (m_State)
	{
	// connection not initiated yet or closed by user
	case TCPStateClosed:
	case TCPStateListen:
	case TCPStateFinWait1:
	case TCPStateFinWait2:
	case TCPStateClosing:
	case TCPStateLastAck:
	case TCPStateTimeWait:
		return Status;

	// connection initiated and not closed by user yet
	case TCPStateCloseWait:	// FIN received from peer, waiting for user to close
	case TCPStateSynSent:
	case TCPStateSynReceived:
	case TCPStateEstablished:
		break;
	}

	Status.bConnected = TRUE;

	if (   m_State == TCPStateCloseWait
	    || m_nErrno < 0
	    || !m_RxQueue.IsEmpty ())
	{
		Status.bRxReady = TRUE;
	}

	if (   m_nErrno < 0
	    || m_TxQueue.GetBytesQueued () < TCP_CONFIG_TX_THRESHOLD)
	{
		Status.bTxReady = TRUE;
	}

	return Status;
}

void CTCPConnection::OnDuplicateAck (void)
{
	m_nDupAckCount++;

	if (m_bFastRecovery)
	{
		// self-provided for the case, that a resent segment is lost
		if (m_nDupAckCount % 3 == 0)
		{
			ResendSegment ();
		}

		// each additional dupACK during recovery inflates cwnd by SMSS and may send new data
		m_nCWND += m_nSND_MSS;
	}
	else if (m_nDupAckCount <= 2)
	{
		SendNewSegment (2 * m_nSND_MSS);	// send new data with inflated cwnd
	}
	else if (m_nDupAckCount == 3)
	{
		onyx_tcp_fast_count++;
		// Fast Retransmit and enter Fast Recovery (Section 3.2)
		m_nSSThresh = max (FLIGHT_SIZE / 2, 2 * m_nSND_MSS);
		m_nRecover = m_nSND_NXT;
		ResendSegment ();
		m_nCWND = m_nSSThresh + 3 * m_nSND_MSS;	// Inflate to account for 3 dupACKs
		m_bFastRecovery = TRUE;
	}
}

void CTCPConnection::ResendSegment (void)
{
	const CNetBuffer *pNetBuffer = m_TxQueue.PeekFirst ();
	if (pNetBuffer == 0)
	{
		return;
	}

	unsigned nFlags = TCP_FLAG_ACK;
	const int *pFlags = (const int *) pNetBuffer->GetPrivateData ();
	assert (pFlags != 0);
	if (!(*pFlags & MSG_MORE))
	{
		nFlags |= TCP_FLAG_PUSH;
	}

	CNetBuffer *pNetBuffer2 = new CNetBuffer (*pNetBuffer);
	assert (pNetBuffer2 != 0);

	SendSegment (nFlags, m_nSND_UNA, m_nRCV_NXT, pNetBuffer2);

	// Onyx: Karn's algorithm -- a segment sent again (a fast retransmit, a partial ACK in
	// fast recovery) gives no RTT sample: its ACK may be for either copy.
	m_RTOCalculator.SegmentResent (m_nSND_UNA);

	StartTimer (TCPTimerRetransmission, m_RTOCalculator.GetRTO ());

	m_nLastSendTicks = m_pTimer->GetTicks ();
}

boolean CTCPConnection::SendSegment (unsigned nFlags, u32 nSequenceNumber, u32 nAcknowledgmentNumber,
				     CNetBuffer *pNetBuffer)
{
	CNetBuffer::TPurpose Purpose = CNetBuffer::TCPSend;

	unsigned nDataOffset = 5;
	assert (nDataOffset * 4 == sizeof (TTCPHeader));
	// Onyx: the window scale option (RFC 7323) in our SYN; in a SYN+ACK only when the peer's
	// SYN had it
	boolean bScaleOption = (nFlags & TCP_FLAG_SYN) && onyx_tcp_ws && (m_bActiveOpen || m_bWindowScale);
	if (nFlags & TCP_FLAG_SYN)
	{
		assert (pNetBuffer == 0);

		Purpose = CNetBuffer::TCPSendMSS;

		nDataOffset++;
		if (bScaleOption)
		{
			nDataOffset++;
		}
	}
	unsigned nHeaderLength = nDataOffset * 4;

	unsigned nDataLength = 0;
	if (pNetBuffer != 0)
	{
		nDataLength = pNetBuffer->GetLength ();
		assert (nDataLength <= m_nSND_MSS);
	}
	else
	{
		pNetBuffer = new CNetBuffer (Purpose);
	}
	assert (pNetBuffer != 0);

	unsigned nPacketLength = nHeaderLength + nDataLength;
	assert (nPacketLength >= nHeaderLength);

	TTCPHeader *pHeader = (TTCPHeader *) pNetBuffer->AddHeader (nHeaderLength);

	pHeader->nSourcePort	 	= le2be16 (m_nOwnPort);
	pHeader->nDestPort	 	= le2be16 (m_nForeignPort);
	pHeader->nSequenceNumber 	= le2be32 (nSequenceNumber);
	pHeader->nAcknowledgmentNumber	= nFlags & TCP_FLAG_ACK ? le2be32 (nAcknowledgmentNumber) : 0;
	pHeader->nDataOffsetFlags	= (nDataOffset << TCP_DATA_OFFSET_SHIFT) | nFlags;
	// Onyx: the window is the room left in the receive queue (it was a constant: a reader that
	// stopped reading did not stop the peer, and the queue grew without a limit), shifted when
	// both sides scale; a SYN's is never shifted.
	if (nFlags & TCP_FLAG_ACK)		// Onyx: nothing is left to acknowledge
	{
		m_nAckPending = 0;
	}

	u32 nWindow = ReceiveWindow ();
	if (nFlags & TCP_FLAG_SYN)
	{
		if (nWindow > TCP_MAX_WINDOW)
		{
			nWindow = TCP_MAX_WINDOW;
		}
		m_nRCV_WND = nWindow;
	}
	else
	{
		nWindow >>= m_nRcvScale;
		if (nWindow > TCP_MAX_WINDOW)
		{
			nWindow = TCP_MAX_WINDOW;
		}
		m_nRCV_WND = nWindow << m_nRcvScale;
		m_nRcvAdvEdge = m_nRCV_NXT + m_nRCV_WND;
	}
	pHeader->nWindow		= le2be16 ((u16) nWindow);
	pHeader->nUrgentPointer		= le2be16 (m_nSND_UP);

	if (nFlags & TCP_FLAG_SYN)
	{
		TTCPOption *pOption = (TTCPOption *) pHeader->Options;

		pOption->nKind   = TCP_OPTION_MSS;
		pOption->nLength = 4;
		pOption->Data[0] = TCP_CONFIG_MSS >> 8;
		pOption->Data[1] = TCP_CONFIG_MSS & 0xFF;

		if (bScaleOption)		// NOP, then kind 3, length 3, the shift
		{
			u8 *pScale = (u8 *) pHeader->Options + 4;
			pScale[0] = TCP_OPTION_NOP;
			pScale[1] = TCP_OPTION_WINDOW_SCALE;
			pScale[2] = 3;
			pScale[3] = TCP_CONFIG_WINDOW_SHIFT;
		}
	}

	pHeader->nChecksum = 0;		// must be 0 for calculation
	pHeader->nChecksum = m_Checksum.Calculate (pHeader, nPacketLength);

#ifdef TCP_DEBUG
	CLogger::Get ()->Write (FromTCP, LogDebug,
				"tx %c%c%c%c%c%c, seq %u, ack %u, win %u, len %u",
				nFlags & TCP_FLAG_URGENT ? 'U' : '-',
				nFlags & TCP_FLAG_ACK    ? 'A' : '-',
				nFlags & TCP_FLAG_PUSH   ? 'P' : '-',
				nFlags & TCP_FLAG_RESET  ? 'R' : '-',
				nFlags & TCP_FLAG_SYN    ? 'S' : '-',
				nFlags & TCP_FLAG_FIN    ? 'F' : '-',
				nSequenceNumber-m_nISS,
				nFlags & TCP_FLAG_ACK ? nAcknowledgmentNumber-m_nIRS : 0,
				m_nRCV_WND,
				nDataLength);

	CLogger::Get ()->Write (FromTCP, LogDebug, "cwd %u, ssthresh %u, dups %u",
				m_nCWND, m_nSSThresh, m_nDupAckCount);
#endif

	assert (m_pNetworkLayer != 0);
	return m_pNetworkLayer->Send (m_ForeignIP, pNetBuffer, IPPROTO_TCP);
}

// Onyx: the room left in the receive queue
u32 CTCPConnection::ReceiveWindow (void) const
{
	if (!onyx_tcp_ws)
	{
		return TCP_CONFIG_WINDOW;
	}

	u32 nQueued = (u32) m_RxQueue.GetBytesQueued ();

	return nQueued < m_nRcvLimit ? m_nRcvLimit - nQueued : 0;
}

void CTCPConnection::ScanOptions (TTCPHeader *pHeader)
{
	assert (pHeader != 0);
	unsigned nDataOffset = TCP_DATA_OFFSET (pHeader->nDataOffsetFlags)*4;
	u8 *pHeaderEnd = (u8 *) pHeader+nDataOffset;
	u16 nFlags = pHeader->nDataOffsetFlags;

	TTCPOption *pOption = (TTCPOption *) pHeader->Options;
	while ((u8 *) pOption+2 <= pHeaderEnd)
	{
		switch (pOption->nKind)
		{
		case TCP_OPTION_END_OF_LIST:
			return;

		case TCP_OPTION_NOP:
			pOption = (TTCPOption *) ((u8 *) pOption+1);
			break;
			
		case TCP_OPTION_MSS:
			if (   pOption->nLength == 4
			    && (u8 *) pOption+4 <= pHeaderEnd)
			{
				u32 nMSS = (u16) pOption->Data[0] << 8 | pOption->Data[1];

				// RFC 1122 section 4.2.2.6
				nMSS = min (nMSS+20, TCP_MSS_S) - TCP_HEADER_LEN - IP_OPTION_SIZE;

				if (   (nFlags & TCP_FLAG_SYN)	// accept in SYN segment only
				    && nMSS >= 10)		// self provided sanity check
				{
					m_nSND_MSS = (u16) nMSS;

					m_nMSS = m_nSND_MSS;

					// set initial congestion window (RFC 5681 section 3.1)
					if (m_nSND_MSS > 2190)
					{
						m_nIW = 2 * m_nSND_MSS;
					}
					else if (m_nSND_MSS > 1095)
					{
						m_nIW = 3 * m_nSND_MSS;
					}
					else
					{
						m_nIW = 4 * m_nSND_MSS;
					}

					m_nCWND = m_nIW;
				}
			}
			// fall through

		default:
			// Onyx: the window scale option of the peer's SYN (RFC 7323). An active
			// open sent it too; a passive one answers with it (SendSegment).
			if (   onyx_tcp_ws
			    && pOption->nKind == TCP_OPTION_WINDOW_SCALE
			    && pOption->nLength == 3
			    && (u8 *) pOption+3 <= pHeaderEnd
			    && (nFlags & TCP_FLAG_SYN)
			    && (m_State == TCPStateSynSent || m_State == TCPStateListen))
			{
				m_bWindowScale = TRUE;
				m_nSndScale = pOption->Data[0] <= 14 ? pOption->Data[0] : 14;
				m_nRcvScale = TCP_CONFIG_WINDOW_SHIFT;
				m_nRcvLimit = TCP_CONFIG_MSS * (u32) (onyx_tcp_window < 44 ? 44 : onyx_tcp_window > 180 ? 180 : onyx_tcp_window);
				m_nSSThresh = TCP_CONFIG_SSTHRESH_SCALED;
			}

			if (pOption->nLength < 2)	// Onyx: a malformed option would loop for ever
			{
				return;
			}

			pOption = (TTCPOption *) ((u8 *) pOption+pOption->nLength);
			break;
		}
	}
}

u32 CTCPConnection::CalculateISN (void)
{
	assert (m_pTimer != 0);
	return   (  m_pTimer->GetTime () * HZ
	          + m_pTimer->GetTicks () % HZ)
	       * (TCP_MAX_WINDOW / TCP_QUIET_TIME / HZ);
}

void CTCPConnection::StartTimer (unsigned nTimer, unsigned nHZ)
{
	assert (nTimer < TCPTimerUnknown);
	assert (nHZ > 0);
	assert (m_pTimer != 0);

	StopTimer (nTimer);

	m_hTimer[nTimer] = m_pTimer->StartKernelTimer (nHZ, TimerStub, (void *) (uintptr) nTimer, this);
}

void CTCPConnection::StopTimer (unsigned nTimer)
{
	assert (nTimer < TCPTimerUnknown);
	assert (m_pTimer != 0);

	m_TimerSpinLock.Acquire ();

	if (m_hTimer[nTimer] != 0)
	{
		m_pTimer->CancelKernelTimer (m_hTimer[nTimer]);
		m_hTimer[nTimer] = 0;
	}

	m_TimerSpinLock.Release ();
}

void CTCPConnection::TimerHandler (unsigned nTimer)
{
	assert (nTimer < TCPTimerUnknown);

	m_TimerSpinLock.Acquire ();

	if (m_hTimer[nTimer] == 0)		// timer was stopped in the meantime
	{
		m_TimerSpinLock.Release ();

		return;
	}

	m_hTimer[nTimer] = 0;

	m_TimerSpinLock.Release ();

	switch (nTimer)
	{
	case TCPTimerRetransmission:
		// Onyx: a connection that has nothing to send again ignores the timer. A peer's RST
		// (a telnet client gone while output flowed), the ACK of our FIN in LAST-ACK, a
		// refused connect closed the connection with this timer running; a terminated
		// connection is kept until its socket releases it (not deleted at the next Process
		// as upstream did), so the timer fired on a CLOSED connection a second later:
		// "Unexpected state 0", a panic any client could cause. Those paths stop the timer
		// now; this is for the handler (an interrupt, maybe another core) racing them.
		if (   m_State == TCPStateClosed
		    || m_State == TCPStateListen
		    || m_State == TCPStateFinWait2
		    || m_State == TCPStateTimeWait)
		{
			break;
		}

		m_RTOCalculator.RetransmissionTimerExpired (m_nSND_UNA);

		if (m_nRetransmissionCount-- == 0)
		{
			m_bTimedOut = TRUE;
			break;
		}

		switch (m_State)
		{
		case TCPStateClosed:
		case TCPStateListen:
		case TCPStateFinWait2:
		case TCPStateTimeWait:
			break;			// (changed meanwhile: nothing to do)

		case TCPStateSynSent:
		case TCPStateSynReceived:
			assert (!m_bSendSYN);
			m_bSendSYN = TRUE;
			break;

		case TCPStateEstablished:
		case TCPStateCloseWait:
			assert (!m_bRetransmit);
			m_bRetransmit = TRUE;
			break;

		case TCPStateFinWait1:
		case TCPStateClosing:
		case TCPStateLastAck:
			assert (!m_bFINQueued);
			m_bFINQueued = TRUE;
			break;
		}
		break;

	case TCPTimerTimeWait:
		NEW_STATE (TCPStateClosed);
		break;

	case TCPTimerUser:
	case TCPTimerUnknown:
		assert (0);
		break;
	}
}

void CTCPConnection::TimerStub (TKernelTimerHandle hTimer, void *pParam, void *pContext)
{
	CTCPConnection *pThis = (CTCPConnection *) pContext;
	assert (pThis != 0);

	unsigned nTimer = (unsigned) (uintptr) pParam;
	assert (nTimer < TCPTimerUnknown);

	pThis->TimerHandler (nTimer);
}

#ifndef NDEBUG

void CTCPConnection::DumpStatus (void)
{
	CLogger::Get ()->Write (FromTCP, LogDebug,
				"sta %u, una %u, snx %u, swn %u, rnx %u, rwn %u, fprt %u",
				m_State,
				m_nSND_UNA-m_nISS,
				m_nSND_NXT-m_nISS,
				m_nSND_WND,
				m_nRCV_NXT-m_nIRS,
				m_nRCV_WND,
				(unsigned) m_nForeignPort);
}

TTCPState CTCPConnection::NewState (TTCPState State, unsigned nLine)
{
	assert (m_State < sizeof s_pStateName / sizeof s_pStateName[0]);
	assert (State < sizeof s_pStateName / sizeof s_pStateName[0]);

	if (m_State != State)
	{
		CLogger::Get ()->Write (FromTCP, LogDebug, "State %s -> %s at line %u",
					s_pStateName[m_State], s_pStateName[State], nLine);
	}

	return m_State = State;
}

void CTCPConnection::UnexpectedState (unsigned nLine)
{
	DumpStatus ();

	CLogger::Get ()->Write (FromTCP, LogPanic, "Unexpected state %u at line %u", m_State, nLine);
}

#endif
