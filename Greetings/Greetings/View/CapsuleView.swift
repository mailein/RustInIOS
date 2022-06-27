import SwiftUI

struct CapsuleView: View{
    var barOffset: [Double]
    var ballOffset: [Double]
    var width: Double
    
    private var barWidth: CGFloat = 1
    private var ballHeight: CGFloat = 10
    
    let VERBOSITY_MODE = true
    
    init(barOffset: [Double] = [0, 0.5, 1], ballOffset: [Double] = [0, 0.5, 1], width: Double = 0){
        self.barOffset = barOffset
        self.ballOffset = ballOffset
        self.width = width
    }
    
    var body: some View{
        GeometryReader{ geometry in
            ZStack(alignment: .leading){
                Capsule()
                    .fill(Color.blue)
                    .frame(height: ballHeight)
                if width != 0 {
                    Capsule()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * width)
                    if VERBOSITY_MODE {
                        Text("\(width)")
                            .foregroundColor(.green)
                            .position(x: 40, y: -10)
                    }
                }
                ForEach(barOffset, id: \.self){bar in
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: barWidth, height: ballHeight)
                        .offset(x: bar * (geometry.size.width - barWidth), y: 0)
                    if VERBOSITY_MODE {
                        Text("\(bar)")
                            .position(x: bar * (geometry.size.width - barWidth), y: -10)
                    }
                }
                ForEach(ballOffset, id: \.self) {ball in
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: ballHeight, height: ballHeight)
                        .offset(x: ball * (geometry.size.width - ballHeight), y: 0)
                    if VERBOSITY_MODE {
                        Text("\(ball)")
                            .foregroundColor(.yellow)
                            .position(x: ball * (geometry.size.width - ballHeight), y: 20)
                    }
                }
            }
        }
        .frame(height: ballHeight)
//        .border(Color.yellow)
    }
}

struct CapsuleView_Previews: PreviewProvider {
    static var previews: some View {
        CapsuleView()
    }
}
