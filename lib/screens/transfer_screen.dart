// lib/screens/transfer_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final Nearby _nearby = Nearby();
  final String _serviceId = 'com.mediqr.transfer';
  bool _advertising = false;
  bool _discovering = false;
  final List<Map<String, dynamic>> _devices = [];
  final List<String> _logs = [];
  String? _connectedEndpoint;

  void _log(String msg) => setState(() => _logs.insert(0, '${DateTime.now().toString().substring(11, 19)} $msg'));

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<void> _startAdvertising() async {
    await _requestPermissions();
    try {
      await _nearby.startAdvertising(
        'MediQR-Device',
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (endpointId, info) async {
          await _nearby.acceptConnection(endpointId,
            onPayLoadRecieved: (endId, payload) => _log('Received payload from $endId'),
            onPayloadTransferUpdate: (endId, update) {},
          );
          _log('Connection from: ${info.endpointName}');
        },
        onConnectionResult: (endpointId, status) {
          if (status == Status.CONNECTED) {
            setState(() => _connectedEndpoint = endpointId);
            _log('Connected to $endpointId');
          }
        },
        onDisconnected: (endpointId) {
          setState(() => _connectedEndpoint = null);
          _log('Disconnected from $endpointId');
        },
        serviceId: _serviceId,
      );
      setState(() => _advertising = true);
      _log('Advertising started');
    } catch (e) {
      _log('Advertising error: $e');
    }
  }

  Future<void> _startDiscovery() async {
    await _requestPermissions();
    try {
      await _nearby.startDiscovery(
        'MediQR-Patient',
        Strategy.P2P_CLUSTER,
        onEndpointFound: (endpointId, name, serviceId) {
          setState(() => _devices.add({'id': endpointId, 'name': name}));
          _log('Found: $name');
        },
        onEndpointLost: (endpointId) {
          setState(() => _devices.removeWhere((d) => d['id'] == endpointId));
        },
        serviceId: _serviceId,
      );
      setState(() => _discovering = true);
      _log('Discovery started');
    } catch (e) {
      _log('Discovery error: $e');
    }
  }

  Future<void> _connectTo(String endpointId, String name) async {
    try {
      await _nearby.requestConnection(
        'MediQR-Patient',
        endpointId,
        onConnectionInitiated: (id, info) async {
          await _nearby.acceptConnection(id,
            onPayLoadRecieved: (endId, payload) => _log('Received file'),
            onPayloadTransferUpdate: (endId, update) {},
          );
        },
        onConnectionResult: (id, status) {
          if (status == Status.CONNECTED) {
            setState(() => _connectedEndpoint = id);
            _log('Connected to $name');
          }
        },
        onDisconnected: (id) {
          setState(() => _connectedEndpoint = null);
          _log('Disconnected');
        },
      );
    } catch (e) {
      _log('Connect error: $e');
    }
  }

  Future<void> _sendFile() async {
    if (_connectedEndpoint == null) {
      _log('No device connected');
      return;
    }
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    final path = result.files.single.path!;
    try {
      await _nearby.sendFilePayload(_connectedEndpoint!, path);
      _log('Sending file...');
    } catch (e) {
      _log('Send error: $e');
    }
  }

  Future<void> _stop() async {
    await _nearby.stopAllEndpoints();
    await _nearby.stopAdvertising();
    await _nearby.stopDiscovery();
    setState(() {
      _advertising = false;
      _discovering = false;
      _connectedEndpoint = null;
      _devices.clear();
    });
    _log('Stopped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('BT / WiFi Transfer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _connectedEndpoint != null ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _connectedEndpoint != null ? Colors.green : Colors.orange),
              ),
              child: Row(children: [
                Icon(
                  _connectedEndpoint != null ? Icons.link : Icons.link_off,
                  color: _connectedEndpoint != null ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                Text(
                  _connectedEndpoint != null ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    color: _connectedEndpoint != null ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            Text('Pharmacist Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _btn('Advertise', Icons.wifi_tethering, _advertising ? null : _startAdvertising,
                active: _advertising)),
              const SizedBox(width: 10),
              Expanded(child: _btn('Send Video', Icons.send, _sendFile)),
            ]),
            const SizedBox(height: 20),

            Text('Patient Mode', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _btn('Discover Devices', Icons.search, _discovering ? null : _startDiscovery,
              active: _discovering, full: true),
            const SizedBox(height: 12),

            if (_devices.isNotEmpty) ...[
              Text('Found Devices', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ..._devices.map((d) => ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                leading: const Icon(Icons.devices, color: Color(0xFF2196F3)),
                title: Text(d['name']),
                trailing: ElevatedButton(
                  onPressed: () => _connectTo(d['id'], d['name']),
                  child: const Text('Connect'),
                ),
              )),
              const SizedBox(height: 12),
            ],

            _btn('Stop All', Icons.stop_circle_outlined, _stop, color: Colors.red, full: true),
            const SizedBox(height: 20),

            Text('Activity Log', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Container(
              height: 160,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text('No activity yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (_, i) => Text(_logs[i],
                        style: const TextStyle(color: Colors.green, fontSize: 11, fontFamily: 'monospace')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, IconData icon, VoidCallback? onTap, {
    bool active = false, Color color = const Color(0xFF2196F3), bool full = false,
  }) {
    final btn = ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.grey : color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return full ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
