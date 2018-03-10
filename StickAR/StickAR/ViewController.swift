import UIKit
import SceneKit.ModelIO
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - Properties
    
    @IBOutlet var sceneView: ARSCNView!
    
    var detectedDataAnchor: ARAnchor?
    var processing = false
    var payload: String!
    var lastPayload: String!
    var payloadList: [String] = []
    
    // MARK: - View Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTap))
        view.addGestureRecognizer(tap)
        
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
                    
                    var changed: Bool
                    // Perform a hit test on the ARFrame to find a surface
                    let hitTestResults = frame.hitTest(center, types: [.featurePoint/*, .estimatedHorizontalPlane, .existingPlane, .existingPlaneUsingExtent*/] )
                    
                    if(self.payload != self.lastPayload) {
                        changed = true
                    }else {
                        changed = false
                    }
                    
                    // If we have a result, process it
                    if let hitTestResult = hitTestResults.first {
                        
                        // If we already have an anchor, update the position of the attached node
                        /*     if(!changed){
                         if let detectedDataAnchor = self.detectedDataAnchor,
                         let node = self.sceneView.node(for: detectedDataAnchor) {
                         //node.transform = SCNMatrix4(hitTestResult.worldTransform)
                         }else {
                         // Detect the first marker
                         self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                         self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                         }
                         
                         } else {*/
                        if(!self.payloadList.contains(self.payload)){
                            // Create an anchor. The node will be created in delegate methods
                            self.detectedDataAnchor = ARAnchor(transform: hitTestResult.worldTransform)
                            self.sceneView.session.add(anchor: self.detectedDataAnchor!)
                        }
                        
                        //               }
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
            
            print(self.payload)
            self.payloadList.append(self.payload)
            
            let scene = SCNScene()
            let wrapperNode = SCNNode()
            var scale: CGFloat = 0
            var height: CGFloat = 0
            var width: CGFloat = 0
            let imageExtensions = ["png", "jpg", "gif"]
            //...
            // Iterate & match the URL objects from your checking results
            let imageURL = URL(string: self.payload)
            let pathExtention = imageURL?.pathExtension
            if imageExtensions.contains(pathExtention!)
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
                                        height = 0.05
                                        width = 0.05 * scale
                                    } else {
                                        scale = image.size.height/image.size.width
                                        width = 0.05
                                        height = 0.05 * scale
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
            }else
            {
                // not a png jpg or gif
                print("Movie URL: \(String(describing: imageURL))")
                
                // Create a 3D Cup to display
                if let url = URL.init(string: "https://cloud.box.com/shared/static/ock9d81kakj91dz1x4ea.obj") {
                    let asset = MDLAsset(url: url)
                    print(asset)
                    let object = asset.object(at: 0)
                    print(object)
                    let modelNode = SCNNode(mdlObject: object)
                    modelNode.name = self.payload
                    scene.rootNode.addChildNode(modelNode)
                }
                /*
                 guard let virtualObjectScene = SCNScene(named: "cup.scn", inDirectory: "Models.scnassets/cup") else {
                 return nil
                 }*/
                
                //   let wrapperNode = SCNNode()
                
                for child in scene.rootNode.childNodes {
                    child.geometry?.firstMaterial?.lightingModel = .physicallyBased
                    child.movabilityHint = .movable
                    wrapperNode.addChildNode(child)
                }
                
                // Set its position based off the anchor
                wrapperNode.transform = SCNMatrix4(anchor.transform)
                
            }
            
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
            
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) -> Void in
                if let name = node.name {
                    if(self.payloadList.contains(name)) {
                        node.removeFromParentNode()
                    }
                }
            }
            self.payloadList = []
            
        
            
            
            
        })
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertPrompt.addAction(confirmAction)
        alertPrompt.addAction(cancelAction)
        
        present(alertPrompt, animated: true, completion: nil)
    }
    
    func httpPost(jsonData: Data) {
        
        let url = URL(string: "http://stickar.diblii.com/upload?=chris")!
        if !jsonData.isEmpty {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = jsonData
            
            URLSession.shared.getAllTasks { (openTasks: [URLSessionTask]) in
                NSLog("open tasks: \(openTasks)")
            }
            
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (responseData: Data?, response: URLResponse?, error: Error?) in
                NSLog("\(response)")
            })
            task.resume()
        }
    }
    /*
     func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
     guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
     return
     }
     
     imgView.image = image
     
     // We use document directory to place our cloned image
     let documentDirectory: NSString = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
     
     // Set static name, so everytime image is cloned, it will be named "temp", thus rewrite the last "temp" image.
     // *Don't worry it won't be shown in Photos app.
     let imageName = "temp"
     let imagePath = documentDirectory.stringByAppendingPathComponent(imageName)
     
     // Encode this image into JPEG. *You can add conditional based on filetype, to encode into JPEG or PNG
     if let data = UIImageJPEGRepresentation(image, 80) {
     // Save cloned image into document directory
     data.writeToFile(imagePath, atomically: true)
     }
     
     // Save it's path
     localPath = imagePath
     
     dismissViewControllerAnimated(true, completion: {
     
     })
     }
     
     func imagePickerControllerDidCancel(picker: UIImagePickerController) {
     dismissViewControllerAnimated(true, completion: nil)
     }
     */
    
}

