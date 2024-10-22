import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
//import 'package:logging/logging.dart';


class HeartBpmService
{
  final CentralManager _manager;
  //late final StreamSubscription _stateChangedSubscription;
  late final StreamSubscription _discoveredSubscription;

  String deviceName = "Polar Sense D8C5F924";
  Peripheral? _peripheral;

  bool _connected = false;
  bool _discovering = false;
  Completer<bool> _connectingResult = Completer<bool>();
  
  HeartBpmService()
    : _manager = CentralManager()
  {
    // _stateChangedSubscription = _manager.stateChanged.listen((eventArgs) async {
      
    // });

    _discoveredSubscription = _manager.discovered.listen((eventArgs) {
      final peripheral = eventArgs.peripheral;
      if (eventArgs.advertisement.name == deviceName && !_connected)
      {
        _connectTo(peripheral);
      }
    });

    _manager.connectionStateChanged.listen((eventArgs) {
      if (eventArgs.peripheral != _peripheral) {
        return;
      }
      if (eventArgs.state == ConnectionState.connected) {
        _connected = true;
        _connectingResult.complete(true);
        log("FIND ME $deviceName");
      } else {
        _connectingResult.complete(false);
      }

      _connectingResult = Completer<bool>();
    });

  }

  Future<void> _connectTo(Peripheral peripheral) async {
    _peripheral = peripheral;
    await stopDiscovery();

    _manager.connect(peripheral);
  }

  Future<bool> connect() async {
    if (_connected) {
      return true;
    }

    if (_discovering) {
      return _connectingResult.future;
    }

    _discovering = true;
    _connected = false;

    Future.delayed(const Duration(seconds: 20), (){
      if (!_connected) {
        _connectingResult.complete(false);
        _connectingResult = Completer<bool>();
        stopDiscovery();
      }
    });

    await _manager.startDiscovery();

    return _connectingResult.future;
  }

  Future<void> stopDiscovery() async {
    if (!_discovering) {
      return;
    }

    await _manager.stopDiscovery();
    _discovering = false;
  }

  int getBpm()
  {
    return 0;
  }
}