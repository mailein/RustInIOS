//
//  RustGreetings.swift
//  Greetings
//
//  Created by Mei Chen on 28.04.21.
//

import Foundation

class RustGreetings {
    func sayHello(to: String) -> String {
        let result = rust_greeting(to)
        let swift_result = String(cString: result!)
        rust_greeting_free(UnsafeMutablePointer(mutating: result))
        return swift_result
    }
    
    func add(a: Int16, b: Int16) -> Int16{
        return rust_add(a,b)
    }
    
//    func initmonitor(s: String) -> String{
//        return java_de_unisaarland_loladrives_sinks_rdevalidator_initmonitor(s);
//    }
}
