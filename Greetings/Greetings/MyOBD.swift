import Foundation
import LTSupportAutomotive

class MyOBD{
    var _serviceUUIDs : [CBUUID]
    var _pids : [LTOBD2Command]
    var _transporter : LTBTLESerialTransporter
    var _obd2Adapter : LTOBD2Adapter?
    var inputStream : InputStream?
    var outputStream : OutputStream?
    
    init(){
        _serviceUUIDs = []
        _pids = []
        _transporter = LTBTLESerialTransporter()
    }
    
    func viewDidLoad () -> () {
        var ma : [CBUUID] = [CBUUID.init(string: "FFF0"), CBUUID.init(string: "FFE0"), CBUUID.init(string: "BEEF"), CBUUID.init(string: "E7810A71-73AE-499D-8C15-FAA9AEF0C3F2")]
        _serviceUUIDs = ma
        self.connect()
    }
    
    func connect () -> () {
        var ma : [LTOBD2Command] = [LTOBD2CommandELM327_IDENTIFY.command(),
                                LTOBD2CommandELM327_IGNITION_STATUS.command(),
                                LTOBD2CommandELM327_READ_VOLTAGE.command(),
                                LTOBD2CommandELM327_DESCRIBE_PROTOCOL.command(),

                                LTOBD2PID_VIN_CODE_0902(),
                                LTOBD2PID_FUEL_SYSTEM_STATUS_03.forMode1(),
                                LTOBD2PID_OBD_STANDARDS_1C.forMode1(),
                                LTOBD2PID_FUEL_TYPE_51.forMode1(),

                                LTOBD2PID_ENGINE_LOAD_04.forMode1(),
                                LTOBD2PID_COOLANT_TEMP_05.forMode1(),
                                LTOBD2PID_SHORT_TERM_FUEL_TRIM_1_06.forMode1(),
                                LTOBD2PID_LONG_TERM_FUEL_TRIM_1_07.forMode1(),
                                LTOBD2PID_SHORT_TERM_FUEL_TRIM_2_08.forMode1(),
                                LTOBD2PID_LONG_TERM_FUEL_TRIM_2_09.forMode1(),
                                LTOBD2PID_FUEL_PRESSURE_0A.forMode1(),
                                LTOBD2PID_INTAKE_MAP_0B.forMode1(),

                                LTOBD2PID_ENGINE_RPM_0C.forMode1(),
                                LTOBD2PID_VEHICLE_SPEED_0D.forMode1(),
                                LTOBD2PID_TIMING_ADVANCE_0E.forMode1(),
                                LTOBD2PID_INTAKE_TEMP_0F.forMode1(),
                                LTOBD2PID_MAF_FLOW_10.forMode1(),
                                LTOBD2PID_THROTTLE_11.forMode1(),

                                LTOBD2PID_SECONDARY_AIR_STATUS_12.forMode1(),
                                LTOBD2PID_OXYGEN_SENSORS_PRESENT_2_BANKS_13.forMode1()]
        
        for index in 0..<8{
            ma.append(LTOBD2PID_OXYGEN_SENSORS_INFO_1.pid(forSensor: UInt(index), mode: 1))
        }
        
        ma.append(LTOBD2PID_OXYGEN_SENSORS_PRESENT_4_BANKS_1D.forMode1())
        ma.append(LTOBD2PID_AUX_INPUT_1E.forMode1())
        ma.append(LTOBD2PID_RUNTIME_1F.forMode1())
        ma.append(LTOBD2PID_DISTANCE_WITH_MIL_21.forMode1())
        ma.append(LTOBD2PID_FUEL_RAIL_PRESSURE_22.forMode1())
        ma.append(LTOBD2PID_FUEL_RAIL_GAUGE_PRESSURE_23.forMode1())
        
        for index in 0..<8{
            ma.append(LTOBD2PID_OXYGEN_SENSORS_INFO_2.pid(forSensor: UInt(index), mode: 1))
        }
        
        ma.append(LTOBD2PID_COMMANDED_EGR_2C.forMode1())
        ma.append(LTOBD2PID_EGR_ERROR_2D.forMode1())
        ma.append(LTOBD2PID_COMMANDED_EVAPORATIVE_PURGE_2E.forMode1())
        ma.append(LTOBD2PID_FUEL_TANK_LEVEL_2F.forMode1())
        ma.append(LTOBD2PID_WARMUPS_SINCE_DTC_CLEARED_30.forMode1())
        ma.append(LTOBD2PID_DISTANCE_SINCE_DTC_CLEARED_31.forMode1())
        ma.append(LTOBD2PID_EVAP_SYS_VAPOR_PRESSURE_32.forMode1())
        ma.append(LTOBD2PID_ABSOLUTE_BAROMETRIC_PRESSURE_33.forMode1())
        
        for index in 0..<8{
            ma.append(LTOBD2PID_OXYGEN_SENSORS_INFO_3.pid(forSensor: UInt(index), mode: 1))
        }
        
        ma.append(LTOBD2PID_CATALYST_TEMP_B1S1_3C.forMode1())
        ma.append(LTOBD2PID_CATALYST_TEMP_B2S1_3D.forMode1())
        ma.append(LTOBD2PID_CATALYST_TEMP_B1S2_3E.forMode1())
        ma.append(LTOBD2PID_CATALYST_TEMP_B2S2_3F.forMode1())
        ma.append(LTOBD2PID_CONTROL_MODULE_VOLTAGE_42.forMode1())
        ma.append(LTOBD2PID_ABSOLUTE_ENGINE_LOAD_43.forMode1())
        ma.append(LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44.forMode1())
        ma.append(LTOBD2PID_RELATIVE_THROTTLE_POS_45.forMode1())
        ma.append(LTOBD2PID_AMBIENT_TEMP_46.forMode1())
        ma.append(LTOBD2PID_ABSOLUTE_THROTTLE_POS_B_47.forMode1())
        ma.append(LTOBD2PID_ABSOLUTE_THROTTLE_POS_C_48.forMode1())
        ma.append(LTOBD2PID_ACC_PEDAL_POS_D_49.forMode1())
        ma.append(LTOBD2PID_ACC_PEDAL_POS_E_4A.forMode1())
        ma.append(LTOBD2PID_ACC_PEDAL_POS_F_4B.forMode1())
        ma.append(LTOBD2PID_COMMANDED_THROTTLE_ACTUATOR_4C.forMode1())
        ma.append(LTOBD2PID_TIME_WITH_MIL_4D.forMode1())
        ma.append(LTOBD2PID_TIME_SINCE_DTC_CLEARED_4E.forMode1())
        ma.append(LTOBD2PID_MAX_VALUE_FUEL_AIR_EQUIVALENCE_RATIO_4F.forMode1())
        ma.append(LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_VOLTAGE_4F.forMode1())
        ma.append(LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_CURRENT_4F.forMode1())
        ma.append(LTOBD2PID_MAX_VALUE_INTAKE_MAP_4F.forMode1())
        ma.append(LTOBD2PID_MAX_VALUE_MAF_AIR_FLOW_RATE_50.forMode1())
        
        _pids = ma
        
        _transporter = LTBTLESerialTransporter.init(identifier: nil, serviceUUIDs: _serviceUUIDs)
        _transporter.connect({(inputStream : InputStream?, outputStream : OutputStream?) -> () in
            if((inputStream == nil)){
                print("Could not connect to OBD2 adapter")
                return;
            }
            self._obd2Adapter = LTOBD2AdapterELM327.init(inputStream: inputStream!, outputStream: outputStream!)
            self._obd2Adapter!.connect()
                                })
        
        _transporter.startUpdatingSignalStrength(withInterval: 1.0)
    }
    
    func updateSensorData () -> () {
        let speed : LTOBD2PID_VEHICLE_SPEED_0D = LTOBD2PID_VEHICLE_SPEED_0D.forMode1()
        _obd2Adapter!.transmitMultipleCommands([speed], completionHandler: {
            (commands : [LTOBD2Command])->() in
            DispatchQueue.main.async {
                print(speed.formattedResponse)
                DispatchQueue.main.asyncAfter(deadline: .now() + (0.3 * Double(NSEC_PER_SEC)) as DispatchTime) {
                    self.updateSensorData()
                }
            }
        })
    }
    
}