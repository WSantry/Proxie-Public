import SwiftUI
import MapKit

struct PopupMapView: View {
    var startLocation: CLLocationCoordinate2D
    var endLocation: CLLocationCoordinate2D
    @Environment(\.presentationMode) var presentationMode
    private let controller = PopupMapController()

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    print("Debug: Close button pressed")
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .padding()
                        .foregroundColor(.black)
                }
                Spacer()
            }
            .padding(.top)

            MapViewRepresentable(startLocation: startLocation, endLocation: endLocation)
                .edgesIgnoringSafeArea(.all)

            // Display the calculated distance within a Text view
            Text("Distance: \(formattedDistance) km")
                .padding()
        }
    }

    // Computed property to calculate and format the distance
    private var formattedDistance: String {
        let distance = controller.calculateDistance(from: startLocation, to: endLocation)
        print("Debug: Calculated distance between start and end: \(String(format: "%.2f", distance)) km")
        return String(format: "%.2f", distance)
    }
}

struct MapViewRepresentable: UIViewRepresentable {
    var startLocation: CLLocationCoordinate2D
    var endLocation: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        print("Debug: makeUIView called")
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false

        // Add annotations
        let startAnnotation = MKPointAnnotation()
        startAnnotation.coordinate = startLocation
        startAnnotation.title = "Start"
        print("Debug: Adding start annotation at \(startLocation)")

        let endAnnotation = MKPointAnnotation()
        endAnnotation.coordinate = endLocation
        endAnnotation.title = "End"
        print("Debug: Adding end annotation at \(endLocation)")

        mapView.addAnnotations([startAnnotation, endAnnotation])

        // Draw line between points
        let polyline = MKPolyline(coordinates: [startLocation, endLocation], count: 2)
        mapView.addOverlay(polyline)
        print("Debug: Added polyline between start and end locations")

        // Set the map region to show both points
        let midPoint = CLLocationCoordinate2D(
            latitude: (startLocation.latitude + endLocation.latitude) / 2,
            longitude: (startLocation.longitude + endLocation.longitude) / 2
        )
        let region = MKCoordinateRegion(center: midPoint, latitudinalMeters: 5000, longitudinalMeters: 5000)
        print("Debug: Setting map region centered at midpoint: \(midPoint)")
        mapView.setRegion(region, animated: true)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        print("Debug: updateUIView called")
    }

    func makeCoordinator() -> Coordinator {
        print("Debug: makeCoordinator called")
        return Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            print("Debug: rendererFor overlay called")
            if let polyline = overlay as? MKPolyline {
                print("Debug: Creating renderer for polyline")
                let renderer = MKPolylineRenderer(overlay: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
