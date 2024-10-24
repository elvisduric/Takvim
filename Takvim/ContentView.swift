import SwiftUI

struct ContentView: View {
    init() {
        // Set the appearance of the TabView's background and its unselected items
        UITabBar.appearance().backgroundColor = UIColor.white
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        let appearance = UITabBarItem.appearance()
        let attributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13, weight: .medium)]
        appearance.setTitleTextAttributes(attributes, for: .normal)
    }

    var body: some View {
        TabView {
            MainContent()
                .tabItem {
                    Image(systemName: "clock")
                    Text("Namaz")
                }
            
            CalendarView(isPresented: .constant(false), selectedDate: .constant(Date()), showCloseButton: false)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Takvim")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Postavke")
                }
        }
        .accentColor(.black)
        .onAppear {
            UITabBar.appearance().barTintColor = UIColor.white // Apply white background for the TabView
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
