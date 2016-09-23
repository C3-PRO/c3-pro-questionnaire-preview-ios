//
//  ViewController.swift
//  Questionnaires
//
//  Created by Pascal Pfiffner on 23.09.16.
//

import UIKit
import C3PRO
import SMART


class ViewController: UIViewController {
	
	var smart: Client?
	
	var controller: QuestionnaireController?
	
	@IBOutlet var loadButton: UIButton?
	
	@IBOutlet var urlField: UITextView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		urlField?.layer.cornerRadius = 5
		urlField?.layer.borderColor = UIColor.gray.withAlphaComponent(0.75).cgColor
		urlField?.layer.borderWidth = 1.0 / UIScreen.main.scale
		urlField?.clipsToBounds = true
		urlField?.textContainerInset = UIEdgeInsets(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
		markReady()
	}
	
	
	// MARK: - Actions
	
	@IBAction func loadQuestionnaire(_ sender: UIButton?) {
		guard let url = URL(string: urlField?.text ?? "") else {
			return
		}
		markBusy()
		let base = url.deletingLastPathComponent().deletingLastPathComponent()
		smart = Client(baseURL: base.absoluteString, settings: [:])
		smart?.ready() { error in
			if let error = error {
				print("Ignoring SMART client error: \(error)")
			}
			
			Questionnaire.read(url.lastPathComponent, server: self.smart!.server) { resource, error in
				if let questionnaire = resource as? Questionnaire {
					self.didLoad(questionnaire: questionnaire)
				}
				else if let error = error {
					self.show(error: error, title: "Error Loading Questionnaire")
				}
				self.markReady()
			}
		}
	}
	
	func didLoad(questionnaire: Questionnaire) {
		controller = QuestionnaireController(questionnaire: questionnaire)
		controller?.whenCompleted = { viewController, response in
			if let json = response?.asJSON() {
				if let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]), let js = String(data: data, encoding: String.Encoding.utf8) {
					print("QuestionnaireResponse: \(js)")
				}
			}
			self.dismiss(animated: true)
		}
		controller?.whenCancelledOrFailed = { viewController, error in
			if let error = error {
				self.show(error: error)
			}
			self.dismiss(animated: true)
		}
		controller?.prepareQuestionnaireViewController() { viewController, error in
			if let vc = viewController {
				self.present(vc, animated: true)
			}
			else if let error = error {
				self.show(error: error, title: "Error Preparing Questionnaire")
			}
		}
	}
	
	
	// MARK: - UI
	
	func markBusy() {
		loadButton?.isEnabled = false
		loadButton?.setTitle("Loading...", for: .normal)
	}
	
	func markReady() {
		loadButton?.isEnabled = true
		loadButton?.setTitle("Load", for: .normal)
	}
	
	func show(error: Error, title: String? = nil) {
		let alert = UIAlertController(title: title ?? "Error", message: "\(error)", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel))
		if nil != presentedViewController {
			dismiss(animated: true) {
				self.present(alert, animated: true)
			}
		}
		else {
			present(alert, animated: true)
		}
	}
}

