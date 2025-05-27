//
//  ConfigNightScoutViewController.swift
//  xdrip
//
//  Created by Liu Xudong on 2025/5/19.
//  Copyright © 2025 zDrip. All rights reserved.
//

import UIKit
import SnapKit
import PopupDialog

class ConfigNightScoutViewController: UIViewController {
    
    private let urlTextField = UITextField()
    private let apiSecretTextField = UITextField()
    private let tokenTextField = UITextField()
    private let portTextField = UITextField()
	
//	private lazy var cancelButton: UIButton = {
//		let button = UIButton(type: .system)
//		button.setTitle(R.string.common.common_cancel(), for: .normal)
//		button.titleLabel?.font  = .systemFont(ofSize: 17, weight: .bold)
//		button.setTitleColor(UIColor.rgba(0, 122, 255), for: .normal)
//		return button
//	}()
	
    private lazy var testButton: UIButton = {
		let button = UIButton(type: .system)
		button.setTitle(UserDefaults.standard.isMaster ? R.string.settingsViews.testUrlAndAPIKeyInMasterMode() : R.string.settingsViews.testUrlAndAPIKeyInFollowerMode(), for: .normal)
		button.setTitleColor(.white, for: .normal)
		button.titleLabel?.font  = .systemFont(ofSize: 17)
		button.backgroundColor = .clear
        button.contentHorizontalAlignment = .left
		return button
	}()
	private lazy var doneButton: UIButton = {
		let button = UIButton()
		button.setTitle(R.string.common.done().uppercased(), for: .normal)
		button.roundCorners(radius: 12, corners: nil)
		button.titleLabel?.font  = .systemFont(ofSize: 17, weight: .bold)
		return button
	}()
	
    private let stackView = UIStackView()
	private let activityIndicator = UIActivityIndicatorView(style: .large)
    
	private var messageHandlerVC: PopupDialog?
	
	private var cachedEnabled = UserDefaults.standard.nightScoutEnabled
	private var cachedURL = UserDefaults.standard.nightScoutUrl
	private var cachedToken = UserDefaults.standard.nightScoutToken
	private var cachedApi = UserDefaults.standard.nightScoutAPIKey
	private var cachedPort = UserDefaults.standard.nightScoutPort
	
    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .init(white: 0, alpha: 0.5)
        setupUI()
        updateButtonState()
    }
    
    private func configureTextField(_ textField: UITextField, placeholder: String, keyboardType: UIKeyboardType = .default) {
        textField.placeholder = placeholder
		textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor(white: 0.5, alpha: 0.5)])
        textField.backgroundColor = .clear
		textField.textColor = .white
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.keyboardType = keyboardType
		textField.returnKeyType = .done
		textField.delegate = self
        textField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }
    }
    
    private func setupUI() {
		view.backgroundColor = ConstantsUI.mainBackgroundColor
		let contentView = UIView()
//		contentView.roundCorners(radius: 16, corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
		contentView.addGestureRecognizer(UITapGestureRecognizer(closure: { gesture in
			self.view.endEditing(true)
		}))
        // 标题
		self.title = "NIGHTSCOUT"
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward")?.withTintColor(.white, renderingMode: .alwaysOriginal), style: .plain, closure: { item in
			self.backAction()
		})
//        let titleLabel = UILabel()
//        titleLabel.text = "NIGHTSCOUT"
//        titleLabel.textColor = .white
//		titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
//        titleLabel.textAlignment = .center
//		cancelButton.addTarget(self, action: #selector(cancelAction), for: .touchUpInside)
        // textfields
        configureTextField(urlTextField, placeholder: "URL", keyboardType: .URL)
        urlTextField.addTarget(self, action: #selector(urlChanged), for: .editingChanged)
		urlTextField.text = cachedURL
		
        configureTextField(apiSecretTextField, placeholder: "API Secret")
		apiSecretTextField.text = cachedApi
		
        configureTextField(tokenTextField, placeholder: "Token")
        tokenTextField.addTarget(self, action: #selector(textFieldsChanged), for: .editingChanged)
		tokenTextField.text = cachedToken
        
        configureTextField(portTextField, placeholder: "Port", keyboardType: .numberPad)
		portTextField.text = UserDefaults.standard.nightScoutPort == 0 ? nil : String(UserDefaults.standard.nightScoutPort)
		
		let stackSuperView = UIView()
		stackSuperView.backgroundColor = ConstantsUI.contentBackgroundColor
		stackSuperView.roundCorners(radius: 16, corners: nil)
        // stackView
        stackView.axis = .vertical
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(urlTextField)
        stackView.addArrangedSubview(apiSecretTextField)
        stackView.addArrangedSubview(tokenTextField)
        stackView.addArrangedSubview(portTextField)
		stackView.addArrangedSubview(testButton)
        
        // testButton
        testButton.addTarget(self, action: #selector(testConnection), for: .touchUpInside)
        
        // doneButton
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        
        // activityIndicator
		activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        
        // 布局
		view.addSubview(contentView)
//		contentView.addSubview(titleLabel)
//		contentView.addSubview(cancelButton)
		contentView.addSubview(doneButton)
		contentView.addSubview(stackSuperView)
		stackSuperView.addSubview(stackView)
		contentView.addSubview(activityIndicator)
        
		contentView.snp.makeConstraints { make in
			make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
			make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
			make.leading.trailing.equalToSuperview()
		}
//		cancelButton.snp.makeConstraints { make in
//			make.centerY.equalTo(titleLabel)
//			make.leading.equalToSuperview().inset(16)
//		}
//		
//        titleLabel.snp.makeConstraints { make in
//			make.top.equalToSuperview().offset(12)
//            make.centerX.equalToSuperview()
//        }
		stackSuperView.snp.makeConstraints { make in
//            make.top.equalTo(titleLabel.snp.bottom).offset(16)
			make.top.equalToSuperview().inset(16)
			make.leading.trailing.equalToSuperview().inset(16)
        }
		stackView.snp.makeConstraints { make in
			make.leading.equalToSuperview().inset(16)
			make.top.bottom.equalToSuperview().inset(8)
			make.trailing.equalToSuperview()
		}
        doneButton.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview().inset(16)
			make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(52)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc private func urlChanged() {
        // 自动提取 token
        
		if let enteredURL = (urlTextField.text ?? "").toNilIfLength0() {

			var urlString = enteredURL
			if "http://".startsWith(urlString) || "https://".startsWith(urlString) {
				urlTextField.text = "https://"
				return;
			}
			if !urlString.startsWith("http://") && !urlString.startsWith("https://") {
				urlString = "https://" + urlString
			}
			if urlString.last == "/" {
				urlString.removeLast()
			}
			urlString = urlString.replacingOccurrences(of: "/api/v1", with: "")
			if let enteredURLComponents = URLComponents(string: urlString) {
				if let port = enteredURLComponents.port {
					portTextField.text = String(port)
				}

				if let user = enteredURLComponents.user {
					apiSecretTextField.text = user.toNilIfLength0()
				}

				if let token = enteredURLComponents.queryItems?.first(where: { $0.name == "token" })?.value {
					tokenTextField.text = token.toNilIfLength0()
				}

				var nighScoutURLComponents = URLComponents()
				nighScoutURLComponents.scheme = enteredURLComponents.scheme
				nighScoutURLComponents.host = enteredURLComponents.host?.lowercased()

				urlTextField.text = nighScoutURLComponents.string!
			}

		}
        updateButtonState()
    }
    
    @objc private func textFieldsChanged() {
        updateButtonState()
    }
    
    private func updateButtonState() {
        let urlNotEmpty = !(urlTextField.text ?? "").isEmpty
        let tokenNotEmpty = !(tokenTextField.text ?? "").isEmpty
        let enable = urlNotEmpty && tokenNotEmpty
		testButton.isEnabled = enable
		testButton.alpha = enable ? 1 : 0.5
		doneButton.isEnabled = enable
		if enable {
			doneButton.setTitleColor(.white, for: .normal)
			doneButton.backgroundColor = ConstantsUI.accentRed
		} else {
			doneButton.setTitleColor(.init(white: 1, alpha: 0.2), for: .normal)
			doneButton.backgroundColor = .init(white: 1, alpha: 0.1)
		}
	}
    
	private func setData() {
		// 保存到 UserDefaults
		if let portString = portTextField.text,
		   let port = Int(portString) {
			UserDefaults.standard.nightScoutPort = port
		}
		UserDefaults.standard.nightScoutAPIKey = apiSecretTextField.text?.toNilIfLength0()
		UserDefaults.standard.nightScoutToken = tokenTextField.text?.toNilIfLength0()
		UserDefaults.standard.nightScoutUrl = urlTextField.text?.toNilIfLength0()
	}
	
	@objc private func cancelAction() {
		// 保存到 UserDefaults
		UserDefaults.standard.nightScoutEnabled = cachedEnabled
		UserDefaults.standard.nightScoutUrl = cachedURL
		UserDefaults.standard.nightScoutAPIKey = cachedApi
		UserDefaults.standard.nightScoutToken = cachedToken
		UserDefaults.standard.nightScoutPort = cachedPort
		self.dismiss(animated: true)
	}
	
	@objc private func backAction() {
		// 保存到 UserDefaults
		UserDefaults.standard.nightScoutEnabled = cachedEnabled
		UserDefaults.standard.nightScoutUrl = cachedURL
		UserDefaults.standard.nightScoutAPIKey = cachedApi
		UserDefaults.standard.nightScoutToken = cachedToken
		UserDefaults.standard.nightScoutPort = cachedPort
		self.navigationController?.popViewController(animated: true)
	}
	
    @objc private func testConnection() {
        view.endEditing(true)
		setData()
		guard UserDefaults.standard.nightScoutUrl != nil else {
			callMessageHandlerInMainThread(title: R.string.common.warning(), message: R.string.settingsViews.dialog_ns_input_url_before_test())
			return
		}
		testButton.isEnabled = false
		activityIndicator.startAnimating()
		callMessageHandlerInMainThread(title: Texts_NightScoutTestResult.nightScoutAPIKeyAndURLStartedTitle, message: Texts_NightScoutTestResult.nightScoutAPIKeyAndURLStartedBody)

		testNightScoutCredentials()
    }
    
	private func testNightScoutCredentials() {
		let resultCallback = { [weak self] (success: Bool, error: Error?)  in
			DispatchQueue.main.async {
				self?.testButton.isEnabled = true
				self?.activityIndicator.stopAnimating()
			}
			if success {
				self?.callMessageHandlerInMainThread(title: Texts_NightScoutTestResult.verificationSuccessfulAlertTitle,
						message: Texts_NightScoutTestResult.verificationSuccessfulAlertBody)

			} else {
				let errorCode = (error as NSError?)?.code ?? 0
				self?.callMessageHandlerInMainThread(
						title: R.string.nightScoutTestResult.dialog_title_nightScoutResult_verification_failed(),
						message: R.string.nightScoutTestResult.dialog_msg_nightScoutResult_verification_failed(errorCode)
				)
			}
		}

		if UserDefaults.standard.isMaster {

		} else {
			self.activityIndicator.startAnimating()
			NightScoutFollowManager.testNightScoutCredentials(resultCallback)
		}
	}

	private func callMessageHandlerInMainThread(title: String, message: String) {
		// unwrap messageHandler
		
		DispatchQueue.main.async {
			let messageHandlerVC = PopupDialog(
				title: title,
				message: message,
				actionTitle: R.string.common.common_Ok(),
				actionHandler: nil,
				dismissHandler: nil
			)
			if self.messageHandlerVC == nil {
				self.messageHandlerVC = messageHandlerVC
				self.present(messageHandlerVC, animated: true)
			} else {
				self.messageHandlerVC?.dismiss({
					self.messageHandlerVC = messageHandlerVC
					self.present(messageHandlerVC, animated: true)
				})
			}
		}
	}
	
    @objc private func doneTapped() {
		setData()
		UserDefaults.standard.nightScoutEnabled = true
		self.navigationController?.popViewController(animated: true)
    }
}

extension ConfigNightScoutViewController: UITextFieldDelegate {
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
	}
}
