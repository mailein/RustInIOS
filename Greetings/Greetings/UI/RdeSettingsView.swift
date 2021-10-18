import SwiftUI

struct RdeSettingsView: View{
    var obd: MyOBD
    
    @State var sliderValue: Double = 83
    
    var body: some View{
        VStack{
            Text("RDE Test configuration")
                .font(.title)
            Text("Choose a distance for your test ride")
                .font(.subheadline)
                .foregroundColor(.gray)
            Spacer()
            Text("\(Int(sliderValue)) km")
                .font(.system(size: 60))
            Slider(value: $sliderValue, in: 48...100)
                .padding(10)
            NavigationLink(destination: HelpView(), label: {
                Text("An RDE ride takes between 90 and 120 mimnutes, and has to be at least 48km long. For more detailed information about RDE rides, simply click on this text.")
                    .foregroundColor(.gray)
            })
            Spacer()
            NavigationLink(destination: RdeView(obd: obd)){
                Text("Start")
                    .bold()
                    .font(.title2)
                    .frame(width: 280, height: 50)
                    .background(Color(.systemRed))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .navigationBarItems(trailing: ConnectedDisconnectedView(connected: false))
        .padding(30)
    }
}

struct RdeSettingView_Previews: PreviewProvider {
    static var previews: some View {
        RdeSettingsView(obd: MyOBD())
    }
}
