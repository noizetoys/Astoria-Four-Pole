//
//  Program Editor View.swift
//  Astoria Filter Editor
//
//  Created by James B. Majors on 11/20/25.
//

import SwiftUI

struct Program_Editor_View: View {
    var editorViewModel: EditorViewModel
    
    private var program: MiniWorksProgram { editorViewModel.program }

    
        // For Debugging
    private func describeSize(_ proxy: GeometryProxy, width wD: CGFloat, height hD: CGFloat) -> String {
        let proxyWidth = String(format: "%.0f", proxy.size.width)
        let proxyHeight = String(format: "%.0f", proxy.size.height)
        let adjustedWidth = String(format: "%.0f", proxy.size.width * wD)
        let adjustedHeight = String(format: "%.0f", proxy.size.height * hD)
        return "Size for (\(proxyWidth),\(proxyHeight)):\n  width: \(adjustedWidth),  height: \(adjustedHeight)"
    }
    
    
    private func cut(_ proxy: GeometryProxy, by div: CGFloat, isWidth: Bool = true) -> CGFloat {
        let value = isWidth ? proxy.size.width : proxy.size.height
        return value * div
    }
    
    
    var body: some View {
        GeometryReader { geometry in
            
            VStack{
                // Top
                topViews(geometry)
                
                // Middle
                middleViews(geometry)
                
                
               // Bottom
                bottomViews(geometry)
            }
            .padding(.horizontal)
        }
        
    }
    
    
    private func topViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            VCF_Editor_View(program: program)
            .frame(maxWidth: cut(geometry, by: 1/3))
//            .padding(.top, 30)
            
            LPF_Editor_View(program: program)
        }
        
    }
    
    
    private func middleViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            MIDIMonitorView(editorViewModel: editorViewModel)
                .frame(maxWidth: geometry.size.width * (1/3))
            
            GroupBox {
                LFOAnimationView(lfoSpeed: program.lfoSpeed,
                                 lfoShape: program.lfoShape,
                                 lfoModulationSource: program.lfoSpeedModulationSource,
                                 lfoModulationAmount: program.lfoSpeedModulationAmount)
            }
            .background(Color.blue.opacity(0.2))
        }
        
    }
    
    
    private func bottomViews(_ geometry: GeometryProxy) -> some View {
        HStack {
            VCA_Editor_View(program: program)
//                            .frame(maxWidth: cut(geometry, by: 2), maxHeight: cut(geometry, by: 3, isWidth: false))
//                            .padding(.top, 30)

//            colorthing(color: .red, geometry: geometry, width: 1/3, height: 1/3)
            Pan_Editor(program: program)
                .frame(maxWidth: cut(geometry, by: 1/3))
            
            Volume_Editor(program: program)
        }
    }
    
    
    private func colorthing(color: Color, geometry: GeometryProxy, width: CGFloat, height: CGFloat) -> some View {
        let newWidth = cut(geometry, by: width)
        let newHeight = cut(geometry, by: height, isWidth: false)
        
        return color
            .cornerRadius(10)
            .overlay {
                Text(describeSize(geometry, width: width, height: height))
                    .font(.title)
                    .multilineTextAlignment(.center)
            }
            .frame(width: newWidth, height: newHeight)
    }
}


#Preview {
    @Previewable @State var editorViewModel = EditorViewModel()
        //    @Previewable @State var program = MiniWorksProgram()
    
    Program_Editor_View(editorViewModel: editorViewModel)
        .frame(width: 1200, height: 800)
}
