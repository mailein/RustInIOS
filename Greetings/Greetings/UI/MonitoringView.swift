import SwiftUI
import LTSupportAutomotive

struct MonitoringView: View {
    var commands : [LTOBD2PID] = []
    var body: some View {
        VStack{
            Text("Speed")
            Text("-")
            Text("km/h")
            Text("RPM")
            Text("-")
            Text("rpm")
            Spacer()
        }
        
//        List(commands, id: \.self) { command in
//            VStack{
//                Text("\(command.description):")
//                Spacer()
//                Text("\(command.formattedResponse)")
//            }
//        }
    }
}

struct MonitoringView_Previews: PreviewProvider {
    static var previews: some View {
        MonitoringView()
    }
}
