import SwiftUI

struct ProfilesView: View {
    @EnvironmentObject var viewModel: ViewModel
//    @Binding var profiles: [Profile]//model
    
    var body: some View {
        List {
            ForEach($viewModel.model.profiles) { $profile in
                NavigationLink(destination: ProfileEditView(profile: $profile)){
                    Text(profile.name)
                    if profile.isSelected{
                        Text("(selected)")
                    }
                }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false){
                        Button(role: .destructive){
                            viewModel.deleteProfile(profile)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false){
                        Button{
                            viewModel.selectProfile(profile)
                        } label: {
                            //UI changes
                            if profile.isSelected {
                                Label("Deselect", systemImage: "pin.slash")
                            }else{
                                Label("Select", systemImage: "pin")
                            }
                        }
                    }
            }
            .onDelete(perform: delete)
            .onMove(perform: reorder)
        }
        .toolbar{
            ToolbarItem(placement: .bottomBar){
                NewButton()
            }
            ToolbarItem(placement: .bottomBar){
                EditButton()
            }
        }
//        .buttonStyle(.borderedProminent)
        .navigationTitle("Profiles")
    }
    func NewButton()-> Button<Text> {
        Button("New"){
            let commands = ProfileCommands.commands
            viewModel.addProfile(Profile("new profile", commands: commands))
        }
    }
    func delete(at offsets: IndexSet) {
        viewModel.model.profiles.remove(atOffsets: offsets)
        if !viewModel.model.profiles.isEmpty {
            let selected = viewModel.model.selectedProfile
            let index = viewModel.model.profiles.firstIndex(of: selected)
            if offsets.contains(index!) {
                viewModel.selectProfile(viewModel.model.profiles[0])
            }
        }
    }
    func reorder(from source: IndexSet, to destination: Int){
        viewModel.model.profiles.move(fromOffsets: source, toOffset: destination)
    }
    func indexOf(profile: Profile) -> Int {
        for index in 0..<viewModel.model.profiles.count{//don't use ForEach(0..<viewModel.model.profiles.count, \.self){index in ...}
            if profile.id == viewModel.model.profiles[index].id {
                return index
            }
        }
        return 0
    }
}

//MARK: -
struct IndexedCollection<Base: RandomAccessCollection>: RandomAccessCollection {
    typealias Index = Base.Index
    typealias Element = (index: Index, element: Base.Element)

    let base: Base

    var startIndex: Index { base.startIndex }

    var endIndex: Index { base.endIndex }

    func index(after i: Index) -> Index {
        base.index(after: i)
    }

    func index(before i: Index) -> Index {
        base.index(before: i)
    }

    func index(_ i: Index, offsetBy distance: Int) -> Index {
        base.index(i, offsetBy: distance)
    }

    subscript(position: Index) -> Element {
        (index: position, element: base[position])
    }
}

extension RandomAccessCollection {
    func indexed() -> IndexedCollection<Self> {
        IndexedCollection(base: self)
    }
}

//MARK: -

//struct ProfilesView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfilesView()
//    }
//}
