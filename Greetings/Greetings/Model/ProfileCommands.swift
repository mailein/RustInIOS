import Foundation
import LTSupportAutomotive

enum ProfileCommands{
    static let commands: [CommandItem] = [
        CommandItem(pid: "05", name: "ENGINE COOLANT TEMPERATURE", unit: "°C", obdCommand: LTOBD2PID_COOLANT_TEMP_05.forMode1()),
        CommandItem(pid: "0C", name: "RPM", unit: "rpm", obdCommand: LTOBD2PID_ENGINE_RPM_0C.forMode1()),
        CommandItem(pid: "0D", name: "SPEED", unit: "km/h", obdCommand: LTOBD2PID_VEHICLE_SPEED_0D.forMode1()),
        CommandItem(pid: "0F", name: "INTAKE AIR TEMPERATURE", unit: "°C", obdCommand: LTOBD2PID_INTAKE_TEMP_0F.forMode1()),
        CommandItem(pid: "10", name: "MAF AIR FLOW RATE", unit: "g/s", obdCommand: LTOBD2PID_MAF_FLOW_10.forMode1()),
        CommandItem(pid: "24", name: "OXYGEN SENSOR 1", unit: "LAMBDA | V", obdCommand: LTOBD2PID_OXYGEN_SENSOR_INFO_2_SENSOR_0_24.forMode1()), //TODO: volts %, ratio V
        CommandItem(pid: "2C", name: "COMMANDED EGR", unit: "%", obdCommand: LTOBD2PID_COMMANDED_EGR_2C.forMode1()),
        CommandItem(pid: "2D", name: "EGR ERROR", unit: "%", obdCommand: LTOBD2PID_EGR_ERROR_2D.forMode1()),
        CommandItem(pid: "2F", name: "FUEL TANK LEVEL INPUT", unit: "%", obdCommand: LTOBD2PID_FUEL_TANK_LEVEL_2F.forMode1()),
        CommandItem(pid: "3C", name: "CATALYST TEMPERATURE 1 1", unit: "°C", obdCommand: LTOBD2PID_CATALYST_TEMP_B1S1_3C.forMode1()),
        CommandItem(pid: "3D", name: "CATALYST TEMPERATURE 2 1", unit: "°C", obdCommand: LTOBD2PID_CATALYST_TEMP_B2S1_3D.forMode1()),
        CommandItem(pid: "3E", name: "CATALYST TEMPERATURE 1 2", unit: "°C", obdCommand: LTOBD2PID_CATALYST_TEMP_B1S2_3E.forMode1()),
        CommandItem(pid: "3F", name: "CATALYST TEMPERATURE 2 2", unit: "°C", obdCommand: LTOBD2PID_CATALYST_TEMP_B2S2_3F.forMode1()),
        CommandItem(pid: "44", name: "FUEL AIR EQUIVALENCE RATIO", unit: "LAMBDA", obdCommand: LTOBD2PID_AIR_FUEL_EQUIV_RATIO_44.forMode1()),
        CommandItem(pid: "46", name: "AMBIENT AIR TEMPERATURE", unit: "°C", obdCommand: LTOBD2PID_AMBIENT_TEMP_46.forMode1()),
        CommandItem(pid: "4F", name: "MAXIMUM FUEL AIR EQUIVALENCE RATIO", unit: "LAMBDA", obdCommand: LTOBD2PID_MAX_VALUE_FUEL_AIR_EQUIVALENCE_RATIO_4F.forMode1()),
        CommandItem(pid: "4F", name: "MAXIMUM OXYGEN SENSOR VOLTAGE", unit: "V", obdCommand:  LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_VOLTAGE_4F.forMode1()),
        CommandItem(pid: "4F", name: "MAXIMUM OXYGEN SENSOR CURRENT", unit: "mA", obdCommand: LTOBD2PID_MAX_VALUE_OXYGEN_SENSOR_CURRENT_4F.forMode1()),
        CommandItem(pid: "4F", name: "MAXIMUM INTAKE MAP", unit: "kPa", obdCommand: LTOBD2PID_MAX_VALUE_INTAKE_MAP_4F.forMode1()),
        CommandItem(pid: "50", name: "MAXIMUM AIR FLOW RATE", unit: "g/s", obdCommand: LTOBD2PID_MAX_VALUE_MAF_AIR_FLOW_RATE_50.forMode1()),
        CommandItem(pid: "51", name: "FUEL TYPE", unit: "Type", obdCommand: LTOBD2PID_FUEL_TYPE_51.forMode1()),
        CommandItem(pid: "5C", name: "ENGINE OIL TEMPERATURE", unit: "°C", obdCommand: LTOBD2PID_ENGINE_OIL_TEMP_5C.forMode1()),
        CommandItem(pid: "5E", name: "ENGINE FUEL RATE", unit: "L/h", obdCommand: LTOBD2PID_ENGINE_FUEL_RATE_5E.forMode1()),
        CommandItem(pid: "66", name: "MAF AIR FLOW RATE SENSOR", unit: "g/s", obdCommand: LTOBD2PID_MASS_AIR_FLOW_SNESOR_66.forMode1()),
        CommandItem(pid: "68", name: "INTAKE AIR TEMPERATURE SENSOR", unit: "°C", obdCommand: LTOBD2PID_INTAKE_AIR_TEMP_SENSOR_68.forMode1()),
        CommandItem(pid: "83", name: "NOX SENSOR", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_83.forMode1()),
        CommandItem(pid: "86", name: "PARTICULATE MATTER SENSOR", unit: "mg/m^3", obdCommand: LTOBD2PID_PATICULATE_MATTER_SENSOR_86.forMode1()),
        CommandItem(pid: "9D", name: "ENGINE FUEL RATE MULTI", unit: "g/s", obdCommand: LTOBD2PID_ENGINE_FUEL_RATE_MULTI_9D.forMode1()),
        CommandItem(pid: "9E", name: "ENGINE EXHAUST FLOW RATE", unit: "kg/h", obdCommand: LTOBD2PID_ENGINE_EXHAUST_FLOW_RATE_9E.forMode1()),
        CommandItem(pid: "A1", name: "NOX SENSOR CORRECTED", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_CORRECTED_A1.forMode1()),
        CommandItem(pid: "A7", name: "NOX SENSOR ALTERNATIVE", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_ALTERNATIVE_A7.forMode1()),
        CommandItem(pid: "A8", name: "NOX SENSOR CORRECTED ALTERNATIVE", unit: "ppm", obdCommand: LTOBD2PID_NOX_SENSOR_CORRECTED_ALTERNATIVE_A8.forMode1())
    ]
    
    static let supportedCommands: [CommandItem] = [
        CommandItem(pid: "00", name: "SUPPORTED COMMANDS1 00", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_00.forMode1()),
        CommandItem(pid: "20", name: "SUPPORTED COMMANDS1 20", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_20.forMode1()),
        CommandItem(pid: "40", name: "SUPPORTED COMMANDS1 40", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_40.forMode1()),
        CommandItem(pid: "60", name: "SUPPORTED COMMANDS1 60", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_60.forMode1()),
        CommandItem(pid: "80", name: "SUPPORTED COMMANDS1 80", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_80.forMode1()),
        CommandItem(pid: "A0", name: "SUPPORTED COMMANDS1 A0", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_A0.forMode1()),
        CommandItem(pid: "C0", name: "SUPPORTED COMMANDS1 C0", unit: "", obdCommand: LTOBD2PID_SUPPORTED_COMMANDS1_C0.forMode1()),
    ]
}
