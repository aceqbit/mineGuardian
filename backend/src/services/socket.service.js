// Socket.io Service — Real-time WebSocket handlers
let ioInstance = null;

const setupSocketHandlers = (io) => {
  ioInstance = io;

  io.on('connection', (socket) => {
    console.log(`🔌 Socket connected: ${socket.id}`);

    // Join zone room (supervisor joins their zone room to receive live updates)
    socket.on('join_zone', ({ zone, uid, role }) => {
      socket.join(`zone:${zone}`);
      socket.join(`user:${uid}`);
      console.log(`📡 ${role} ${uid} joined zone:${zone}`);
      socket.emit('joined', { zone, status: 'connected' });
    });

    // Join supervisor room
    socket.on('join_supervisor_room', ({ supervisorUid, zone }) => {
      socket.join(`supervisor:${supervisorUid}`);
      socket.join(`zone:${zone}`);
      console.log(`👷 Supervisor ${supervisorUid} monitoring zone:${zone}`);
    });

    // Disconnect
    socket.on('disconnect', () => {
      console.log(`🔌 Socket disconnected: ${socket.id}`);
    });
  });
};

// Emit hazard report to supervisor dashboard (zone room)
const emitHazardReport = (zone, hazardData) => {
  if (!ioInstance) return;
  ioInstance.to(`zone:${zone}`).emit('new_hazard', {
    type: 'hazard_report',
    data: hazardData,
    timestamp: new Date().toISOString(),
  });
  console.log(`📡 Hazard emitted to zone:${zone}`);
};

// Emit checklist submission to supervisor dashboard
const emitChecklistSubmission = (zone, checklistData) => {
  if (!ioInstance) return;
  ioInstance.to(`zone:${zone}`).emit('checklist_submitted', {
    type: 'checklist_submit',
    data: checklistData,
    timestamp: new Date().toISOString(),
  });
};

// Emit shift status update
const emitShiftUpdate = (zone, shiftData) => {
  if (!ioInstance) return;
  ioInstance.to(`zone:${zone}`).emit('shift_update', {
    type: 'shift_update',
    data: shiftData,
    timestamp: new Date().toISOString(),
  });
};

// Emit SOS alert to supervisor
const emitSOSAlert = (zone, sosData) => {
  if (!ioInstance) return;
  ioInstance.to(`zone:${zone}`).emit('sos_alert', {
    type: 'sos_alert',
    data: sosData,
    timestamp: new Date().toISOString(),
    priority: 'CRITICAL',
  });
};

module.exports = {
  setupSocketHandlers,
  emitHazardReport,
  emitChecklistSubmission,
  emitShiftUpdate,
  emitSOSAlert,
};
