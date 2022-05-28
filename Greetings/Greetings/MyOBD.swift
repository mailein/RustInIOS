import Foundation
import LTSupportAutomotive
import CoreLocation
import SwiftUI
import pcdfcore

class MyOBD: ObservableObject{
    // OBD
    private var _serviceUUIDs : [CBUUID]
//    var _pids : [LTOBD2Command]
    private var _transporter : LTBTLESerialTransporter
    private var _obd2Adapter : LTOBD2Adapter?
    private var supportedPids: [Int] //pid# in decimal
    private var rdeCommands: [CommandItem] // The sensor profile of the car which is determined.
    private var fuelRateSupported: Bool
    private var faeSupported: Bool
    private var supportedPidCommands: [LTOBD2PID]
    private var fuelType: LTOBD2PID
    
    // LOLA
    private let rustGreetings = RustGreetings()
//    let fileContent = specFile(filename: "rde-lola-test-drive-spec-no-percentile1.lola")//even if it's in a folder, no need to add folder name
    private var specBody: String
    private var specHeader: String
    private var specFuelRateInput: String
    private var specFuelRateToCo2Diesel: String
    private var specFuelRateToEMFDiesel: String
    private var specFuelRateToCo2Gasoline: String
    private var specFuelRateToEMFGasoline: String
    private var specMAFToFuelRateDieselFAE: String
    private var specMAFToFuelRateDiesel: String
    private var specMAFToFuelRateGasolineFAE: String
    private var specMAFToFuelRateGasoline: String
    
    @Published var mySpeed : String = "No data"
    @Published var myAltitude : String = "No data"
    @Published var myTemp : String = "No data"
    @Published var myNox: String = "No data"
    @Published var myFuelRate: String = "No data"
    @Published var myMAFRate: String = "No data"

    @Published var myAirFuelEqvRatio: String = "No data"
    @Published var myCoolantTemp: String = "No data"
    @Published var myRPM: String = "No data"
    @Published var myIntakeTemp: String = "No data"
    @Published var myMAFRateSensor: String = "No data"
    @Published var myOxygenSensor1: String = "No data"
    @Published var myCommandedEgr: String = "No data"
    @Published var myFuelTankLevelInput: String = "No data"
    @Published var myCatalystTemp11: String = "No data"
    @Published var myCatalystTemp12: String = "No data"
    @Published var myCatalystTemp21: String = "No data"
    @Published var myCatalystTemp22: String = "No data"
    @Published var myMaxValueFuelAirEqvRatio: String = "No data"
    @Published var myMaxValueOxygenSensorVoltage: String = "No data"
    @Published var myMaxValueOxygenSensorCurrent: String = "No data"
    @Published var myMaxValueIntakeMAP: String = "No data"
    @Published var myMaxAirFlowRate: String = "No data"
    @Published var myFuelType: String = "No data"
    @Published var myEngineOilTemp: String = "No data"
    @Published var myIntakeAirTempSensor: String = "No data"
    @Published var myNoxCorrected: String = "No data"
    @Published var myNoxAlternative: String = "No data"
    @Published var myNoxCorrectedAlternative: String = "No data"
    @Published var myPmSensor: String = "No data"
    @Published var myEngineFuelRateMulti: String = "No data"
    @Published var myEngineExhaustFlowRate: String = "No data"
    @Published var myEgrError: String = "No data"
    
    private var startTime: Date?
    private var locationHelper: LocationHelper
    
    //RTLola outputs
    @Published var outputValues : [String: Double]
    
    //ppcdf
    private var fileName: String
    
    //UI
    private var connected: Bool // maybe later isConnected will be different than isOngoing, if we keep the bluetooth connected all the time
    private var isLiveMonitoring: Bool //if true, use selectedProfile, otherwise use rdeProfile from buildSpec()
    private var isOngoing: Bool
    private var selectedCommands: [CommandItem]
    private var connectedAdapterName: String
    
    init(){
        _obd2Adapter = nil
        
        _serviceUUIDs = []
        _transporter = LTBTLESerialTransporter()
        supportedPids = []
        rdeCommands = []
        for c in ProfileCommands.commands {
            rdeCommands.append(CommandItem(pid: c.pid, name: c.name, unit: c.unit, obdCommand: c.obdCommand))
        }
        fuelRateSupported = false
        faeSupported = false
        supportedPidCommands = ProfileCommands.supportedCommands.map{$0.obdCommand}
        fuelType = ProfileCommands.commands.getByPid(pid: "51")!.obdCommand
        
        startTime = nil
        locationHelper = LocationHelper()
        
        outputValues = [String: Double]()
        fileName = ""
        connected = false
        isLiveMonitoring = false
        isOngoing = false
        selectedCommands = []
        for c in ProfileCommands.commands {
            selectedCommands.append(CommandItem(pid: c.pid, name: c.name, unit: c.unit, obdCommand: c.obdCommand))
        }
        connectedAdapterName = ""
        
        //load spec file
        specBody = specFile(filename: "spec_body.lola")
        specHeader = specFile(filename: "spec_header.lola")
        specFuelRateInput = specFile(filename: "spec_fuel_rate_input.lola")
        specFuelRateToCo2Diesel = specFile(filename: "spec_fuel_rate_to_co2_diesel.lola")
        specFuelRateToEMFDiesel = specFile(filename: "spec_fuel_rate_to_emf_diesel.spec")
        specFuelRateToCo2Gasoline = specFile(filename: "spec_fuelrate_to_co2_gasoline.lola")
        specFuelRateToEMFGasoline = specFile(filename: "spec_fuelrate_to_emf_gasoline.lola")
        specMAFToFuelRateDieselFAE = specFile(filename: "spec_maf_to_fuel_rate_diesel_fae.lola")
        specMAFToFuelRateDiesel = specFile(filename: "spec_maf_to_fuel_rate_diesel.lola")
        specMAFToFuelRateGasolineFAE = specFile(filename: "spec_maf_to_fuel_rate_gasoline_fae.lola")
        specMAFToFuelRateGasoline = specFile(filename: "spec_maf_to_fuel_rate_gasoline.lola")
    }
    
    //MARK: - life cycle
    public func viewDidLoad (isLiveMonitoring isLive: Bool, selectedCommands selected: [CommandItem]) -> () {
        resetState(isLive: isLive, selected: selected) // reset at the beginning, so that the state is freezed at the end
        isOngoing = true
        if _obd2Adapter == nil { //the first time to run rde test / live monitoring
            _serviceUUIDs = [CBUUID.init(string: "FFF0"), CBUUID.init(string: "FFE0"), CBUUID.init(string: "BEEF"), CBUUID.init(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")]
            
            //use notificationcenter, only call updateSensorData() when adapter status is Discovering / Connected
            NotificationCenter.default.addObserver(self, selector: #selector(onAdapterChangedState), name: Notification.Name(LTOBD2AdapterDidUpdateState), object: nil)
        }
        self.fileName = genFileName()
        //get timestamp
        if self.startTime == nil {
            self.startTime = Date()
        }
        let duration = Date().timeIntervalSince(self.startTime!)
        genEvent(duration: duration)
        self.connect()
    }
    
    private func connect () -> () {
        _transporter = LTBTLESerialTransporter.init(identifier: nil, serviceUUIDs: _serviceUUIDs)
        //The closure is called after transporter has connected! So updateSensorData() should be called inside the closure after adapter connects; emmmm, no need, because when the state changed to connected, updateSensorData() will be called
        _transporter.connect{(inputStream : InputStream?, outputStream : OutputStream?) -> () in
            if((inputStream == nil)){
                print("Could not connect to OBD2 adapter")
                return;
            }
            self._obd2Adapter = LTOBD2AdapterELM327.init(inputStream: inputStream!, outputStream: outputStream!)
            self._obd2Adapter!.connect()
            print("adapter init and connected")
            self.connected = true
            
            //It seems the correct obd BLE can be automatically discovered and connected,
            //so I only need to show green(connected) or red(disconnected).
            //Unnecessary to show all possible adapters.
            self.connectedAdapterName = self._transporter.getAdapter().name!
            let allDevices = self._transporter.getAllDevices()
            print("adapter: \(self._transporter.getAdapter()), all devices: \(allDevices)")
        }
        _transporter.startUpdatingSignalStrength(withInterval: 1.0)
    }
    
    public func disconnect (completion: @escaping (Result<URL, Error>)->Void) {
        _obd2Adapter?.disconnect()
        _transporter.disconnect()
        connected = false
        isOngoing = false
    }
    
    //MARK: - delegate
    @objc func onAdapterChangedState(){
        DispatchQueue.main.async {
            switch self._obd2Adapter?.adapterState{
            case OBD2AdapterStateConnected://OBD2AdapterStateDiscovering,
                print("onAdapterChangedState: \(self._obd2Adapter?.friendlyAdapterState)")
                self.updateSensorDataForSupportedPids()
            default:
                print("Unhandled adapter state \(self._obd2Adapter?.friendlyAdapterState)")
            }
        }
    }
    
    //MARK: - access to properties
    public func getSelectedCommands() -> [CommandItem] {
        return self.selectedCommands
    }
    
    public func getRdeCommands() -> [CommandItem] {
        return self.rdeCommands
    }
    
    public func setLocationHelper(_ locationHelper: LocationHelper) {
        self.locationHelper = locationHelper
    }
    
    public func isLiveMonitoringOngoing() -> Bool { return isLiveMonitoring && isOngoing }
    
    public func isConnected() -> Bool { return self.connected }
    
    public func isLiveMonitoringMode() -> Bool { return self.isLiveMonitoring }
    
    public func isRunning() -> Bool { return self.isOngoing }
    
    public func getConnectedAdapterName() -> String { return self.connectedAdapterName }
    
    //MARK: - supported pids
    private func updateSensorDataForSupportedPids() {
//        let pid900 = LTOBD2PID_VIN_CODE_0902.init()//LTOBD2PID_VIN_CODE_0902.init() causes the bluetooth to fail "The connection has timed out unexpectedly."
        updateSensorDataForSupportedPid(commands: self.supportedPidCommands, index: 0)
    }
    
    private func updateSensorDataForSupportedPid(commands: [LTOBD2PID], index: Int) {
        let pidCommand = commands[index]
        self._obd2Adapter?.transmitCommand(pidCommand, responseHandler: {_ in
            DispatchQueue.main.async {
                //get timestamp
                let duration = Date().timeIntervalSince(self.startTime!)
                if (pidCommand.gotValidAnswer) {
                    //generate SupportedPidsEvent
                    let startIndex = pidCommand.commandString.startIndex
                    let i = pidCommand.commandString.index(pidCommand.commandString.startIndex, offsetBy: 2)
                    self.genEvent(command: pidCommand, duration: duration, isSupportedPidsCommand: true)
                    
                    //get supported pids
                    var bitmap: [Bool] = []
                    let cooked: [NSNumber] = pidCommand.cookedResponse.values.first!
                    for num in cooked {
                        let b = self.decimal2Bitmap(num: num.intValue)
                        bitmap.append(contentsOf: b)
                    }
                    for (i, b) in bitmap.enumerated() {
                        if b && (i+1) % 32 != 0{ // %32 to eliminate pids of supported pids
                            self.supportedPids.append(index * 32 + i + 1)//+1 because $01~$20 starts from 0
                        }
                    }
                    print("index: \(index), support \(self.supportedPids)")
                    
                    // recursive to the next supportedPidCommand
                    if pidCommand.cookedResponse.values.first!.last!.intValue % 2 == 1 && index < 6{
                        //D0 is odd number means the next supportedPid is supported.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.updateSensorDataForSupportedPid(commands: commands, index: index + 1)
                        }
                    } else {
                        //generate Error Event for unsupported commands
                        var commandItems: [CommandItem] = self.rdeCommands
                        if self.isLiveMonitoring {
                            commandItems = self.selectedCommands
                        }
                        let unsupported = commandItems.filter{ !self.supportedPids.contains(Int($0.pid, radix: 16)!) }
                        self.genEvent(unsupportedCommands: unsupported, duration: Date().timeIntervalSince(self.startTime!))
                        
                        //fuelType
                        self._obd2Adapter?.transmitCommand(self.fuelType, responseHandler: {_ in
                            DispatchQueue.main.async {
                                //get timestamp
                                let duration = Date().timeIntervalSince(self.startTime!)
                                self.genEvent(command: self.fuelType, duration: duration)
                                self.myFuelType = self.fuelType.formattedResponse
                                
                                let supported = self.checkSupportedPids(supportedPids: self.supportedPids, fuelType: self.myFuelType)
                                //TODO: if not supported, throw exception?
                                if supported {
                                    let specFile = self.buildSpec()
                                    self.rustGreetings.initmonitor(s: specFile)
                                    self.updateSensorData(commandItems: commandItems)
                                }else{
                                    print("ERROR: Car is NOT compatible for RDE tests.")
                                }
                            }
                        })
                    }
                }
            }
        })
    }
    
    private func checkSupportedPids(supportedPids: [Int], fuelType: String) -> Bool {
        rdeCommands = []
        // If the car is not a diesel or gasoline, the RDE test is not possible since there are no corresponding
        // specifications.
        if (fuelType != "Diesel" && fuelType != "Gasoline") {
            print("Incompatible for RDE: Fuel type unknown or invalid ('\(fuelType)')")
            return false
        }
        
        // Velocity information to determine acceleration, distance travelled and to calculate the driving dynamics.
        if (supportedPids.contains(0x0D)) {
            rdeCommands.append(CommandItem(pid: "0D", name: "SPEED", unit: "km/h", obdCommand: LTOBD2PID_VEHICLE_SPEED_0D.forMode1(), enabled: true))
        } else {
            print("Incompatible for RDE: Speed data not provided by the car.")
            return false
        }

        // Ambient air temperature for checking compliance with the environmental constraints.
        if (supportedPids.contains(0x46)) {
            rdeCommands.append(CommandItem(pid: "46", name: "AMBIENT AIR TEMPERATURE", unit: "°C", obdCommand: LTOBD2PID_AMBIENT_TEMP_46.forMode1(), enabled: true))
        } else {
            print("Incompatible for RDE: Ambient air temperature not provided by the car.")
            return false
        }

        // NOx sensor(s) to check for violation of the EU regulations.
        if supportedPids.contains(0x83) {
            rdeCommands.append(CommandItem(pid: "83", name: "NOX SENSOR", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_83.forMode1(), enabled: true))
        } else if supportedPids.contains(0xA1) {
            rdeCommands.append(CommandItem(pid: "A1", name: "NOX SENSOR CORRECTED", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_CORRECTED_A1.forMode1(), enabled: true))
        } else if supportedPids.contains(0xA7) {
            rdeCommands.append(CommandItem(pid: "A7", name: "NOX SENSOR ALTERNATIVE", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_ALTERNATIVE_A7.forMode1(), enabled: true))
        } else if supportedPids.contains(0xA8) {
            rdeCommands.append(CommandItem(pid: "A8", name: "NOX SENSOR CORRECTED ALTERNATIVE", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_CORRECTED_ALTERNATIVE_A8.forMode1(), enabled: true))
        } else {
            print("Incompatible for RDE: NOx sensor not provided by the car.")
            return false
        }

        // Fuelrate sensors for calculation of the exhaust mass flow. Can be replaced through MAF.
        // TODO: ask Maxi for the EMF PID
        if supportedPids.contains(0x5E) {
            rdeCommands.append(CommandItem(pid: "5E", name: "ENGINE FUEL RATE", unit: "L/h", obdCommand: LTOBD2PID_ENGINE_FUEL_RATE_5E.forMode1(), enabled: true))
            fuelRateSupported = true
        } else if supportedPids.contains(0x9D) {
            rdeCommands.append(CommandItem(pid: "9D", name: "ENGINE FUEL RATE MULTI", unit: "g/s", obdCommand: LTOBD2PID_ENGINE_FUEL_RATE_MULTI_9D.forMode1(), enabled: true))
            fuelRateSupported = true
        } else {
            print("RDE: Fuel rate not provided by the car.")
            fuelRateSupported = false
        }

        // Mass air flow rate for the calcuation of the exhaust mass flow.
        if supportedPids.contains(0x10) {
            rdeCommands.append(CommandItem(pid: "10", name: "MAF AIR FLOW RATE", unit: "g/s", obdCommand: LTOBD2PID_MAF_FLOW_10.forMode1(), enabled: true))
        } else if supportedPids.contains(0x66) {
            rdeCommands.append(CommandItem(pid: "66", name: "MAF AIR FLOW RATE SENSOR", unit: "g/s", obdCommand: LTOBD2PID_MASS_AIR_FLOW_SNESOR_66.forMode1(), enabled: true))
        } else {
            print("Incompatible for RDE: Mass air flow not provided by the car.")
            return false
        }

        // Fuel air equivalence ratio for a more precise calculation of the fuel rate with MAF.
        if (supportedPids.contains(0x44) && !fuelRateSupported) {
            rdeCommands.append(CommandItem(pid: "44", name: "FUEL AIR EQUIVALENCE RATIO", unit: "LAMBDA", obdCommand: LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44.forMode1(), enabled: true))
            faeSupported = true
        } else {
            print("RDE: Fuel air equivalence ratio not provided by the car.")
            faeSupported = false
        }

        print("Car compatible for RDE tests.")

        return true
    }
    
    private func buildSpec() -> String {
        var s = ""
        s.append(specHeader)

        if fuelRateSupported {
            s.append(specFuelRateInput)
        } else {
            if myFuelType == "Diesel" {
                if (faeSupported) {
                    s.append(specMAFToFuelRateDieselFAE)
                } else {
                    s.append(specMAFToFuelRateDiesel)
                }
            }
            if myFuelType == "Gasoline" {
                if (faeSupported) {
                    s.append(specMAFToFuelRateGasolineFAE)
                } else {
                    s.append(specMAFToFuelRateGasoline)
                }
            }
        }
        if myFuelType == "Diesel" {
            s.append(specFuelRateToCo2Diesel)
            s.append(specFuelRateToEMFDiesel)
        }
        if myFuelType == "Gasoline"{
            s.append(specFuelRateToCo2Gasoline)
            s.append(specFuelRateToEMFGasoline)
        }
        s.append(specBody)

        return s
    }
    
    //MARK: - loop: send and receive obd commands
    private func updateSensorData (commandItems: [CommandItem]) {
        _obd2Adapter?.transmitMultipleCommands(
            commandItems
            .filter{ supportedPids.contains(Int($0.pid, radix: 16)!) } //only send supported commands
            .map{$0.obdCommand}, completionHandler: {
            (commands : [LTOBD2Command])->() in
            DispatchQueue.main.async {
                //timestamp
                let duration = Date().timeIntervalSince(self.startTime!) //in seconds, because in rust Duration::new(seconds: time, nanoseconds: 0)
                
                //GPS
                let altitude = self.locationHelper.altitude
                self.myAltitude = "\(altitude) m"
                let speedCommand = commandItems.filter{ $0.pid == "0D" }
                let speed = speedCommand[0].obdCommand.cookedResponse.values.first!.first!.doubleValue
                self.genEvent(duration: duration, altitude: altitude, longitude: self.locationHelper.longitude, latitude: self.locationHelper.latitude, speed: speed)
                
                commandItems.forEach { item in
                    let obdCommand = item.obdCommand
                    switch item.pid {
                    case "05":
                        self.myCoolantTemp = obdCommand.formattedResponse
                    case "0C":
                        self.myRPM = obdCommand.formattedResponse
                    case "0D":
                        self.mySpeed = obdCommand.formattedResponse
                    case "0F":
                        self.myIntakeTemp = obdCommand.formattedResponse
                    case "10":
                        self.myMAFRate = obdCommand.formattedResponse
                    case "24":
                        self.myOxygenSensor1 = obdCommand.formattedResponse
                    case "2C":
                        self.myCommandedEgr = obdCommand.formattedResponse
                    case "2D":
                        self.myEgrError = obdCommand.formattedResponse
                    case "2F":
                        self.myFuelTankLevelInput = obdCommand.formattedResponse
                    case "3C":
                        self.myCatalystTemp11 = obdCommand.formattedResponse
                    case "3D":
                        self.myCatalystTemp21 = obdCommand.formattedResponse
                    case "3E":
                        self.myCatalystTemp12 = obdCommand.formattedResponse
                    case "3F":
                        self.myCatalystTemp22 = obdCommand.formattedResponse
                    case "44":
                        self.myAirFuelEqvRatio = obdCommand.formattedResponse
                    case "46":
                        self.myTemp = obdCommand.formattedResponse
                    case "4F":
                        switch item.unit {
                        case "LAMBDA":
                            self.myMaxValueFuelAirEqvRatio = obdCommand.formattedResponse
                        case "V":
                            self.myMaxValueOxygenSensorVoltage = obdCommand.formattedResponse
                        case "mA":
                            self.myMaxValueOxygenSensorCurrent = obdCommand.formattedResponse
                        case "kPa":
                            self.myMaxValueIntakeMAP = obdCommand.formattedResponse
                        default:
                            print("pid 4F, no match unit")
                        }
                    case "50":
                        self.myMaxAirFlowRate = obdCommand.formattedResponse
                    case "51":
                        self.myFuelType = obdCommand.formattedResponse
                    case "5C":
                        self.myEngineOilTemp = obdCommand.formattedResponse
                    case "5E":
                        self.myFuelRate = obdCommand.formattedResponse
                    case "66":
                        self.myMAFRateSensor = obdCommand.formattedResponse
                    case "68":
                        self.myIntakeAirTempSensor = obdCommand.formattedResponse
                    case "83":
                        self.myNox = obdCommand.formattedResponse
                    case "86":
                        self.myPmSensor = obdCommand.formattedResponse
                    case "9D":
                        self.myEngineFuelRateMulti = obdCommand.formattedResponse
                    case "9E":
                        self.myEngineExhaustFlowRate = obdCommand.formattedResponse
                    case "A1":
                        self.myNoxCorrected = obdCommand.formattedResponse
                    case "A7":
                        self.myNoxAlternative = obdCommand.formattedResponse
                    case "A8":
                        self.myNoxCorrectedAlternative = obdCommand.formattedResponse
                    default:
                        print("pid \(item.pid), no match case")
                    }
                    self.genEvent(command: obdCommand, duration: duration)
                    self.printCommandResponse(command: obdCommand)
                }
                
                let inputCommands: [LTOBD2PID] = self.rdeCommands.map{ $0.obdCommand }
                let gotValidAnswers: [LTOBD2PID] = inputCommands.filter{ $0.gotValidAnswer }
                if inputCommands.count ==  gotValidAnswers.count {
                    //TODO: which order??? where to insert altitude??? // maybe all ok //TODO: varying count
                    var s = [inputCommands[0].cookedResponse.values.first!.first!.doubleValue,//speed
                             altitude,
                             inputCommands[1].cookedResponse.values.first!.first!.doubleValue,//temp
                             inputCommands[2].cookedResponse.values.first!.first!.doubleValue,//nox
                             inputCommands[3].cookedResponse.values.first!.first!.doubleValue,//fuelrate
                             inputCommands[4].cookedResponse.values.first!.first!.doubleValue,//mafrate
                             duration]

                    let output = self.rustGreetings.sendevent(inputs: &s, len_in: UInt32(s.count))
                    if !output.isEmpty {//don't publish empty array, otherwise the rde view will display it
                        self.outputValues = output
                        print("*********** rtlola outputs: \(self.outputValues)")
                    }
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.updateSensorData(commandItems: commandItems)
                }
            }
        })
    }
    
    //MARK: - pcdf events
    //MetaEvent
    private func genEvent(duration: TimeInterval){
        let event = MetaEvent(source: "app id",
                              timestamp: Int64(duration * 1000000000),
                              pcdf_type: "PERSISTENT",
                              ppcdf_version: "1.0.0",
                              ipcdf_version: nil)
        writeEventToFile(event: event, createFile: true)
    }
    
    //GPSEvent
    private func genEvent(duration: TimeInterval,
                             altitude: CLLocationDistance?,
                             longitude: CLLocationDegrees?,
                             latitude: CLLocationDegrees?,
                             speed: Double?){
        var event: PCDFEvent
        if altitude != nil, longitude != nil, latitude != nil, speed != nil {
            event = GPSEvent(source: "Phone-GPS",
                             timestamp: Int64(duration * 1000000000),//seconds -> nanoseconds
                             longitude: longitude!, latitude: latitude!,
                             altitude: altitude!,
                             speed: KotlinDouble(double: speed!))
        }else{
            event = ErrorEvent(source: "GPS unavailable",
                               timestamp: Int64(duration * 1000000000),
                               message: "altitude: \(altitude), longitude: \(longitude), latitude: \(latitude), gps_speed: \(speed)")
        }
        writeEventToFile(event: event)
    }
    
    //OBDEvent
    private func genEvent(command: LTOBD2PID,
                             duration: TimeInterval,
                             isSupportedPidsCommand: Bool = false) {
        if command.gotValidAnswer {
            let header = command.cookedResponse.first!.key
            let commandString = command.commandString
            let responseArray = command.cookedResponse.first!.value
            let range = commandString.startIndex..<commandString.index(after: commandString.startIndex)
            var response = commandString.replacingCharacters(in: range, with: "4")
            responseArray.forEach{ r in
                let hexStr = String(Int(truncating: r), radix: 16, uppercase: true)
                response.append(hexStr.count == 1 ? "0\(hexStr)" : hexStr)//decimal -> hex
            }
            print("add to event: \(command.cookedResponse), \(String(describing: header)), \(response)")
            
            var event: PCDFEvent
            if isSupportedPidsCommand {
                let cooked: [NSNumber] = command.cookedResponse.values.first!
                let supportedPids: [Int] = cooked.map({$0.intValue})
                event = SupportedPidsEvent(source: "ECU-\(header)", timestamp: Int64(duration * 1000000000), bytes: response, pid: Int32(command.commandString.suffix(2)) ?? -1, mode: Int32(command.commandString.prefix(2)) ?? 1, supportedPids: NSMutableArray.init(array: supportedPids))
            } else {
                event = OBDEvent(source: "ECU-\(header)", timestamp: Int64(duration * 1000000000), bytes: response)//duration is in seconds, timestamp is in nanoseconds
            }
            writeEventToFile(event: event)
        }
    }
    
    //unsupported pids
    private func genEvent(unsupportedCommands: [CommandItem], duration: TimeInterval) {
        var commandNames = ""
        unsupportedCommands.forEach{ c in
            commandNames.append("\(c.name), ")
        }
        if !commandNames.isEmpty {//remove last two char
            commandNames.remove(at: commandNames.index(before: commandNames.endIndex))
            commandNames.remove(at: commandNames.index(before: commandNames.endIndex))
        }
        let event = ErrorEvent(source: "Unsupported pid",
                               timestamp: Int64(duration * 1000000000),
                               message: "The following OBD-Commands selected for tracking were not supported: \(commandNames)")
        writeEventToFile(event: event)
    }
    
    //MARK: - file system
    private func genFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .short
        let fileName = "\(dateFormatter.string(from: Date())).ppcdf"
        return fileName
    }
    
    private func writeEventToFile(event: PCDFEvent, createFile: Bool = false) {
        let file = self.fileName
        EventStore.save(to: file, event: event, createFile: createFile){ result in
            if case .success(_) = result {
                print("successfully saved event \(event) to ppcdf file \(file)")
            }
        }
    }
    
    //MARK: - helper methods
    private func printCommandResponse(command: LTOBD2PID){
        print("============== \(command.description), cookedResponse: \(command.cookedResponse), formattedResponse: \(command.formattedResponse), commandString: \(command.commandString), completionTime: \(command.completionTime), failureResponse: \(command.failureResponse), freezeFrame: \(command.freezeFrame), gotAnswer: \(command.gotAnswer), gotValidAnswer: \(command.gotValidAnswer), isCAN: \(command.isCAN), isRawCommand: \(command.isRawCommand), purpose: \(command.purpose), rawResponse: \(command.rawResponse), selectedECU: \(command.selectedECU)")
    }
    
    private func decimal2Bitmap(num: Int) -> [Bool]{
        let str = UInt8(num).binaryDescription
        var ret = Array(repeating: false, count: 8)
        for (i, s) in str.enumerated() {
            if s == "1" {
                ret[i] = true
            }
        }
        return ret
    }
    
    private func initCommands( commands: inout [CommandItem]) {
        commands = []
        for c in ProfileCommands.commands {
            commands.append(CommandItem(pid: c.pid, name: c.name, unit: c.unit, obdCommand: c.obdCommand))
        }
    }
    
    private func resetState(isLive: Bool, selected: [CommandItem]){
        _serviceUUIDs = []
        _transporter = LTBTLESerialTransporter()
//        _obd2Adapter = nil
        supportedPids = []
        initCommands(commands: &rdeCommands)
        fuelRateSupported = false
        faeSupported = false
        supportedPidCommands = ProfileCommands.supportedCommands.map{$0.obdCommand}
        fuelType = ProfileCommands.commands.getByPid(pid: "51")!.obdCommand
        
        startTime = nil
        
        outputValues = [String: Double]()
        fileName = ""
//        isConnected = false
        isLiveMonitoring = isLive
        isOngoing = false
        if isLive{
            selectedCommands = selected
        }else{
            initCommands(commands: &selectedCommands)
        }
        connectedAdapterName = ""
        
        mySpeed = "No data"
        myAltitude = "No data"
        myTemp = "No data"
        myNox = "No data"
        myFuelRate = "No data"
        myMAFRate = "No data"
        
        myAirFuelEqvRatio = "No data"
        myCoolantTemp = "No data"
        myRPM = "No data"
        myIntakeTemp = "No data"
        myMAFRateSensor = "No data"
        myOxygenSensor1 = "No data"
        myCommandedEgr = "No data"
        myFuelTankLevelInput = "No data"
        myCatalystTemp11 = "No data"
        myCatalystTemp12 = "No data"
        myCatalystTemp21 = "No data"
        myCatalystTemp22 = "No data"
        myMaxValueFuelAirEqvRatio = "No data"
        myMaxValueOxygenSensorVoltage = "No data"
        myMaxValueOxygenSensorCurrent = "No data"
        myMaxValueIntakeMAP = "No data"
        myMaxAirFlowRate = "No data"
        myFuelType = "No data"
        myEngineOilTemp = "No data"
        myIntakeAirTempSensor = "No data"
        myNoxCorrected = "No data"
        myNoxAlternative = "No data"
        myNoxCorrectedAlternative = "No data"
        myPmSensor = "No data"
        myEngineFuelRateMulti = "No data"
        myEngineExhaustFlowRate = "No data"
        myEgrError = "No data"
    }
}
