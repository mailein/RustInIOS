import SwiftUI
import pcdfcore

struct RdeLogView: View{
    @EnvironmentObject var viewModel: ViewModel
    @EnvironmentObject var obd: MyOBD
    
    var body: some View{
        TabView{
            RdeResultView(fileName: obd.getFileName())
                .tabItem{
                    Text("Event Log")
                }
        }
        .toolbar{
            ToolbarItem(placement: .navigationBarLeading){
                Button(action: {
                    viewModel.exitRDE()
                }) {
                    HStack(spacing: 0) {
                        Image(systemName: "chevron.backward")
                            .aspectRatio(contentMode: .fill)
                        Text("Configuration")
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing){
                ConnectedDisconnectedView(connected: obd.isConnected())
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct RdeResultView: View{
    let fileName: String
    let outputs: [String: Double]
    
    init(fileName: String) {
        self.fileName = fileName
        do {
            let fileUrl = try EventStore.fileURL(fileName: fileName)
            var events: [PCDFEvent] = []
            EventStore.load(fileURL: fileUrl) { result in
                if case .success(let e) = result {
                    events = e
                }
            }
            let rdeValidator = RDEValidator()
            outputs = try rdeValidator.monitorOffline(data: events)
        } catch {
            print(error.localizedDescription)
            outputs = [:]
        }
    }
    
    var body: some View{
        VStack{
            RdeResultLine(name: "Valid RDE Trip:", image: getValidRdeTrip(), helpMsg: "valid rde trip help msg test test")
            RdeResultLine(name: "Total Duration:", durationText: DurationText(durationInSeconds: Int64(getTotalDuration())))
            RdeResultLine(name: "Total Distance:", distanceText: DistanceText(distanceInMeters: getTotalDistance()))
            RdeResultLine(name: "NOₓ Emissions:", value: "\(getNoxPerKilometer()) mg/km")
            
            RdeResultSection(text: "Urban",
                             t: outputs["d_u"] ?? 0,
                             d: outputs["t_u"] ?? 0,
                             avg: outputs["u_avg_v"] ?? 0,
                             pct: outputs["u_va_pct"] ?? 0,
                             rpa: outputs["u_rpa"] ?? 0)

            RdeResultSection(text: "Rural",
                             t: outputs["d_r"] ?? 0,
                             d: outputs["t_r"] ?? 0,
                             avg: outputs["r_avg_v"] ?? 0,
                             pct: outputs["r_va_pct"] ?? 0,
                             rpa: outputs["r_rpa"] ?? 0)

            RdeResultSection(text: "Motorway",
                             t: outputs["d_m"] ?? 0,
                             d: outputs["t_m"] ?? 0,
                             avg: outputs["m_avg_v"] ?? 0,
                             pct: outputs["m_va_pct"] ?? 0,
                             rpa: outputs["m_rpa"] ?? 0)
            
        }
    }
    
    struct RdeResultSection: View {
        let text: String
        let t: Double
        let d: Double
        let avg: Double
        let pct: Double
        let rpa: Double
        
        var body: some View {
            VStack{
                Divider()
                Text(text).bold()
                RdeResultLine(name: "Duration", durationText: DurationText(durationInSeconds: Int64(t)))
                RdeResultLine(name: "Distance", distanceText: DistanceText(distanceInMeters: d))
                RdeResultLine(name: "Average Speed", value: "\(avg) km/h")
                RdeResultLine(name: "95Percentile(va)", value: "\(pct) m^2/s^3")
                RdeResultLine(name: "RPA", value: "\(rpa) m/s^2")
            }
        }
    }
    
    struct RdeResultLine: View {
        private let name: String
        private var value: String? = nil
        private var image: Image? = nil
        private var duration: DurationText? = nil
        private var distance: DistanceText? = nil
        private var helpMsg: String?
        private let width: CGFloat = 150
        
        @State private var showPopover = false
        
        init(name: String, value: String, helpMsg: String? = nil) {
            self.name = name
            self.value = value
            self.helpMsg = helpMsg
        }
        
        init(name: String, image: Image, helpMsg: String? = nil) {
            self.name = name
            self.image = image
            self.helpMsg = helpMsg
        }
        
        init(name: String, durationText: DurationText, helpMsg: String? = nil) {
            self.name = name
            self.duration = durationText
            self.helpMsg = helpMsg
        }
        
        init(name: String, distanceText: DistanceText, helpMsg: String? = nil) {
            self.name = name
            self.distance = distanceText
            self.helpMsg = helpMsg
        }
        
        var body: some View {
            HStack(alignment: .bottom){
                Text(name)
                    .frame(width: width, alignment: .bottomLeading)
                if value != nil {
                    Text(value!)
                }
                if image != nil {
                    image!
                }
                if duration != nil {
                    duration!
                }
                if distance != nil {
                    distance!
                }
                if helpMsg != nil {
                    Button(action: {
                        showPopover = true
                    }, label: {
                        Image(systemName: "questionmark.circle")
                    })
                    .popover(isPresented: $showPopover, content: {
                        Text(helpMsg!)
                    })
                }
            }
        }
    }
    
    func getValidRdeTrip() -> Image {
        if outputs["is_valid_test_num"] == 1.0 && outputs["not_rde_test_num"] != 0.0 {
            return Image(systemName: "checkmark")
        } else {
            return Image(systemName: "xmark")
        }
    }
    
    func getTotalDuration() -> Double {
        let tu: Double = outputs["t_u"] ?? 0
        let tr: Double = outputs["t_r"] ?? 0
        let tm: Double = outputs["t_m"] ?? 0
        return tu + tr + tm
    }
    
    func getTotalDistance() -> Double {
        let d: Double = outputs["d"] ?? 0
        return d
    }
    
    func getNoxPerKilometer() -> Double {
        let nox: Double = outputs["nox_per_kilometer"] ?? 0
        return nox * 1000
    }
}




