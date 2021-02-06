//
//  FirstViewController.swift
//  Thred
//
//  Created by Arta Koroushnia on 2020-04-01.
//  Copyright © 2020 Thred. All rights reserved.
//

import UIKit
import ColorCompatibility
import GoogleSignIn
import CryptoKit
import AuthenticationServices
import FirebaseAuth

class FirstViewController: UIViewController, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return UIApplication.shared.windows.first!
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
      if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
        guard let nonce = currentNonce else {
          fatalError("Invalid state: A login callback was received, but no login request was sent.")
        }
        guard let appleIDToken = appleIDCredential.identityToken else {
          print("Unable to fetch identity token")
          return
        }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
          print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
          return
        }
        // Initialize a Firebase credential.
        let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                  idToken: idTokenString,
                                                  rawNonce: nonce)
        // Sign in with Firebase.
        Auth.auth().signIn(with: credential) { (authResult, error) in
          if let err = error {
            // Error. If error.code == .MissingOrInvalidNonce, make sure
            // you're sending the SHA256-hashed nonce as a hex string with
            // your request to Apple.
            print(err.localizedDescription)
            return
          }
          // User is signed in to Firebase with Apple.
          // ...
            let name = appleIDCredential.fullName?.givenName
            
            (UIApplication.shared.delegate as? AppDelegate)?.checkToSignIn(result: authResult!, fullName: name)
        }
      }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
      // Handle error.
      print("Sign in with Apple errored: \(error)")
    }
    
    var provider: OAuthProvider?
    
    @IBAction func continueWithYahoo(_ sender: UIButton) {

        provider = OAuthProvider(providerID: "yahoo.com")
        
        provider?.customParameters = [
        "prompt": "login"
        ]
        provider?.scopes = ["profile", "email"]


        provider?.getCredentialAndLogin()
    }
    
    
    @IBAction func continueWithMicrosoft(_ sender: UIButton) {
        
        provider = OAuthProvider(providerID: "microsoft.com")
        
        provider?.customParameters = [
                "prompt": "consent",
                        "login_hint": "",
            ]
        
        provider?.getCredentialAndLogin()
    }
    
    @IBOutlet weak var signInBtn: UIButton!
    
    @IBOutlet weak var appleBtn: UIButton!
    @IBOutlet weak var backgroundMaskView: UIView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var signUpBtn: UIButton!
    @IBOutlet weak var googleBtn: UIButton!
    @IBOutlet weak var microsoftBtn: UIButton!
    @IBOutlet weak var yahooBtn: UIButton!

    @IBOutlet weak var spinner: MapSpinnerView!
    var textToSet: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        spinner.isHidden = true
        GIDSignIn.sharedInstance()?.presentingViewController = self

        
        signInBtn.layer.cornerRadius = signInBtn.frame.height / 2
        signInBtn.clipsToBounds = true
        
        signInBtn.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        signInBtn.layer.borderWidth = 2
        
        googleBtn.superview?.layer.cornerRadius = googleBtn.frame.height / 2
        googleBtn.superview?.clipsToBounds = true
        googleBtn.superview?.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        googleBtn.superview?.layer.borderWidth = 2
        
        appleBtn.superview?.layer.cornerRadius = appleBtn.frame.height / 2
        appleBtn.superview?.clipsToBounds = true
        appleBtn.superview?.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        appleBtn.superview?.layer.borderWidth = 2
        
        microsoftBtn.superview?.layer.cornerRadius = microsoftBtn.frame.height / 2
        microsoftBtn.superview?.clipsToBounds = true
        microsoftBtn.superview?.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        microsoftBtn.superview?.layer.borderWidth = 2
        
        yahooBtn.superview?.layer.cornerRadius = yahooBtn.frame.height / 2
        yahooBtn.superview?.clipsToBounds = true
        yahooBtn.superview?.layer.borderColor = UIColor(named: "signInBorder")?.cgColor
        yahooBtn.superview?.layer.borderWidth = 2
        
        if textToSet == nil{
            textView.text = "Design, Purchase, and more!"
            textView.textColor = .label
        }
        else{
            textView.text = textToSet
            textView.textColor = .systemRed
        }
        
        backgroundMaskView?.addBackgroundBlur(blurEffect: UIBlurEffect(style: UIBlurEffect.Style.systemUltraThinMaterial))
        backgroundMaskView?.alpha = 0.6
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: Array<Character> =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    fileprivate var currentNonce: String?

    @IBAction func continueWithApple(_ sender: UIButton) {
        
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            return String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    override func viewDidLayoutSubviews() {

    }
    @IBAction func googleSignIn(_ sender: UIButton) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupUI()
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    var BubbleTimer:Timer?
    
    func setupUI() {
        BubbleTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.startBubble), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BubbleTimer?.invalidate()
        BubbleTimer = nil
    }
    
    //MARK: - Function Declaration
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension FirstViewController{
    
    @objc func startBubble(){

        let bubbleImageView = UIImageView()
        
        let intRandom = self.generateIntRandomNumber(min: 1, max: 6)
        
        let padding: CGFloat = 3

        bubbleImageView.image = UIImage(named: "thred.logo.light.transparent")?.resizableImage(withCapInsets: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding), resizingMode: .stretch)

        if intRandom % 5 == 0{
            bubbleImageView.backgroundColor = UIColor(red: 0.6902, green: 0.9569, blue: 0.698, alpha: 1.0) /* #b0f4b2 */

        }
        else if intRandom % 2 == 0{
            let color = UIColor(red: 0.5098, green: 0.9176, blue: 1, alpha: 1.0) /* #82eaff */
            bubbleImageView.backgroundColor = color
        }
        else{
            bubbleImageView.backgroundColor = UIColor(red: 1, green: 0.7176, blue: 0.7176, alpha: 1.0) /* #ffb7b7 */


        }
                
        let size = self.randomFloatBetweenNumbers(firstNum: 25, secondNum: 75)
        
        let randomOriginX = self.randomFloatBetweenNumbers(firstNum: self.view.frame.minX, secondNum: self.view.frame.maxX)
        let originy = self.view.frame.maxY - 35
        
        
        bubbleImageView.frame = CGRect(x: randomOriginX, y: originy, width: CGFloat(size), height: CGFloat(size))
        bubbleImageView.alpha = self.randomFloatBetweenNumbers(firstNum: 0.0, secondNum: 1.0)
        bubbleImageView.layer.cornerRadius = bubbleImageView.frame.size.height / 2
        bubbleImageView.contentMode = .scaleAspectFill
        bubbleImageView.clipsToBounds = true
        self.view.addSubview(bubbleImageView)
        self.view.sendSubviewToBack(bubbleImageView)
        let zigzagPath: UIBezierPath = UIBezierPath()
        let oX: CGFloat = bubbleImageView.frame.origin.x
        let oY: CGFloat = bubbleImageView.frame.origin.y
        let eX: CGFloat = oX
        let eY: CGFloat = oY - (self.randomFloatBetweenNumbers(firstNum: self.view.frame.midY, secondNum: self.view.frame.maxY))
        let t = self.randomFloatBetweenNumbers(firstNum: 20, secondNum: 100)
        var cp1 = CGPoint(x: oX - t, y: ((oY + eY) / 2))
        var cp2 = CGPoint(x: oX + t, y: cp1.y)
        
        let r = arc4random() % 2
        if (r == 1){
            let temp:CGPoint = cp1
            cp1 = cp2
            cp2 = temp
        }
        
        zigzagPath.move(to: CGPoint(x: oX, y: oY))
        
        zigzagPath.addCurve(to: CGPoint(x: eX, y: eY), controlPoint1: cp1, controlPoint2: cp2)
        CATransaction.begin()
        CATransaction.setCompletionBlock({() -> Void in
            
            UIView.transition(with: bubbleImageView, duration: 0.1, options: .transitionCrossDissolve, animations: {() -> Void in
                bubbleImageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }, completion: {(_ finished: Bool) -> Void in
                bubbleImageView.removeFromSuperview()
            })
        })
        
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        pathAnimation.duration = 3.5
        pathAnimation.path = zigzagPath.cgPath
        
        pathAnimation.fillMode = CAMediaTimingFillMode.forwards
        pathAnimation.isRemovedOnCompletion = false
        bubbleImageView.layer.add(pathAnimation, forKey: "movingAnimation")
        CATransaction.commit()
        
    }
    
    func generateIntRandomNumber(min: Int, max: Int) -> Int {
        let randomNum = Int(arc4random_uniform(UInt32(max) - UInt32(min)) + UInt32(min))
        return randomNum
    }
    
    func randomFloatBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
}

extension OAuthProvider{
    func getCredentialAndLogin(){
        getCredentialWith(nil) { credential, error in
            
            if error != nil {
                // Handle error.
                print(error?.localizedDescription ?? "")
                
            }
            if let credential = credential {
                Auth.auth().signIn(with: credential) { authResult, error in
                    if error != nil {
                    // Handle error.
                        print(error?.localizedDescription ?? "")
                    }
                    else if let result = authResult{
                        (UIApplication.shared.delegate as? AppDelegate)?.checkToSignIn(result: result)
                    }
                }
            }
            else{
                
            }
        }
    }
}
