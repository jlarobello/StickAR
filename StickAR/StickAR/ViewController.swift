import UIKit
import SceneKit.ModelIO
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var sceneView: ARSCNView!
    
    var detectedDataAnchor: ARAnchor?
    var processing = false
    var restarted = true
    var payload: String!
    var lastPayload: String!
    var payloadList: [String] = []
    
    // MARK: - View Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleTap))
        view.addGestureRecognizer(longPress)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Set the session's delegate
        sceneView.session.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Enable horizontal plane detection
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        // Only run one Vision request at a time
        if self.processing {
            return
        }
        
        self.processing = true
        
        // Create a Barcode Detection Request
        let request = VNDetectBarcodesRequest { (request, error) in
            
            // Get the first result out of the results, if there are any
            if let results = request.results, let result = results.first as? VNBarcodeObservation {
                
                // Comparing last URL detected from QR
                self.lastPayload = self.payload
                self.payload = result.payloadStringValue
                
                // Get the bounding box for the bar code and find the center
                var rect = result.boundingBox
                
                // Flip coordinates
                rect = rect.applying(CGAffineTransform(scaleX: 1, y: -1))
                rect = rect.applying(CGAffineTransform(translationX: 0, y: 1))
                
                // Get center
                let center = CGPoint(x: rect.midX, y: rect.midY)
                
                // Go back to the main thread
                DispatchQueue.main.async {
                    
                    // Perform a hit test on the ARFrame to find a surface
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint] )
                    print(hitTestResults)
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        //print(self.payload)
                            if(!self.payloadList.contains(self.payload)){
                            //print("anchor created")
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            //print(self.detectedDataAnchor)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                            }
                            

                        
                    }
                    
                    // Set processing flag off
                    self.processing = false
                }
                
            } else {
                // Set processing flag off
                self.processing = false
            }
        }
        
        // Process the request in the background
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Set it to recognize QR code only
                request.symbologies = [.QR]
                
                // Create a request handler using the captured image from the ARFrame
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: frame.capturedImage,
                                                                options: [:])
                
                // Process the request
                try imageRequestHandler.perform([request])
            } catch {
                
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("rendering")
        // If this is our anchor, create a node
        if self.detectedDataAnchor?.identifier == anchor.identifier {
            let scene = SCNScene()
            let wrapperNode = SCNNode()
            var scale: CGFloat = 0
            var height: CGFloat = 0
            var width: CGFloat = 0
            let imageExtensions = ["png", "jpg", "jpeg", "gif"]
            let modelExtensions = ["dae", "DAE", "scn"]
            //...
            // Iterate & match the URL objects from your checking results
            let imageURL = URL(string: self.payload)
            let pathExtension = imageURL?.pathExtension
            if imageExtensions.contains(pathExtension!)
            {
                // It is a 2d image
                // Creating a session object with the default configuration.
                // You can read more about it here https://developer.apple.com/reference/foundation/urlsessionconfiguration
                let session = URLSession(configuration: .default)
                
                // Define a download task. The download task will download the contents of the URL as a Data object and then you can do what you wish with that data.
                let downloadPicTask = session.dataTask(with: imageURL!) { (data, response, error) in
                    // The download has finished.
                    if let e = error {
                        print("Error downloading picture: \(e)")
                    } else {
                        // No errors found.
                        // It would be weird if we didn't have a response, so check for that too.
                        if let res = response as? HTTPURLResponse {
                            print("Downloaded picture with response code \(res.statusCode)")
                            if let imageData = data {
                                // Finally convert that Data into an image and do what you wish with it.
                                if let image = UIImage(data: imageData){
                                    if(image.size.width < image.size.height) {
                                        scale = image.size.width/image.size.height
                                        height = 0.1
                                        width = 0.1 * scale
                                    } else {
                                        scale = image.size.height/image.size.width
                                        width = 0.1
                                        height = 0.1 * scale
                                    }
                                    
                                    // Do something with your image.
                                    
                                    
                                    let box = SCNBox(width: width, height: height, length: 0.001, chamferRadius: 0)
                                    let material = SCNMaterial()
                                    material.diffuse.contents = image
                                    box.materials = [material]
                                    let boxNode = SCNNode(geometry: box)
                                    boxNode.name = self.payload
                                    scene.rootNode.addChildNode(boxNode)
                                    
                                    
                                    for child in scene.rootNode.childNodes {
                                        child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                                        child.movabilityHint = .movable
                                        wrapperNode.addChildNode(child)
                                    }
                                    
                                    // Set its position based off the anchor
                                    wrapperNode.transform = SCNMatrix4(anchor.transform)
                                }
                                //                       return wrapperNode
                            } else {
                                print("Couldn't get image: Image is nil")
                            }
                        } else {
                            print("Couldn't get response code for some reason")
                        }
                    }
                }
                
                downloadPicTask.resume()
            }else if(modelExtensions.contains(String(self.payload.characters.suffix(3))))
            {
                // not a png jpg or gif
                
                print("is not a 2d image")
                
                let name: String = self.payload
                let endIndex = name.index(name.endIndex, offsetBy: -4)
                let truncated = name.substring(to: endIndex)
                
                 guard let objectScene = SCNScene(named: name, inDirectory: "art.scnassets/"+truncated) else {
                 return nil
                 }

                
                for child in objectScene.rootNode.childNodes {
                    child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                    child.movabilityHint = .movable
                    wrapperNode.addChildNode(child)
                }
                
                // Set its position based off the anchor
                wrapperNode.transform = SCNMatrix4(anchor.transform)
                
            }
            
            self.payloadList.append(self.payload)
            
            
            
            return wrapperNode
            
        }
        
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            print(position)
            let location: CGPoint = position// for example from a tap gesture recognizer
            let hits = self.sceneView.hitTest(location, options: nil)
            if let tappedNode = hits.first?.node {
                // do something with the tapped node ...
                tappedNode.removeFromParentNode()
            }
        }
    }
    
    @objc func handleTap() {
        if presentedViewController != nil {
            return
        }
        
        let alertPrompt = UIAlertController(title: "Erase all stickers?", message: "", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Confirm", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            
            self.sceneView.session.pause()
            
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
                if let name = node.name {
                    if(self.payloadList.contains(name)) {
                        if(node.childNodes.count > 0) {
                            node.childNodes[node.childNodes.count-1].removeFromParentNode()
                        }
                    }else {
                        node.removeFromParentNode()
                    }
                }
            }
            
            //self.sceneView.session.pause()
            self.payloadList.removeAll()
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
        })
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }
    

    
}

