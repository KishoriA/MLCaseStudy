//
//  InputViewController.swift
//  PredictionPOC
//
//  Created by Agrawal, Kishori (US - Mumbai) on 11/19/18.
//  Copyright © 2018 Agrawal, Kishori (US - Mumbai). All rights reserved.
//

import UIKit
import CoreML

class InputViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    enum Row {
        case age
        case chestPain
        case bloodPressure
        case bloodSugar
        case electro
        case heartRate
        case exercise
    }
    
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var chestPainTextField: UITextField!
    @IBOutlet weak var bpTextField: UITextField!
    @IBOutlet weak var bloodSugarTextField: UITextField!
    @IBOutlet weak var electroTextField: UITextField!
    @IBOutlet weak var heartRateTextField: UITextField!
    @IBOutlet weak var exerciseTextField: UITextField!
    @IBOutlet weak var outputLabel: UILabel!
    
    let predictorModel = StructuredModel()
    let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 250))
    
    let chestPainOptions = ["chest_pain_asympt", "chest_pain_atyp_angina", "chest_pain_non_anginal", "chest_pain_typ_angina"]
    let electroOptions = ["rest_electro_normal", "rest_electro_left_vent_hyper", "rest_electro_st_t_wave_abnormality"]
    let exerciseOptions = ["yes", "no"]
    
    var selectedRow: Row?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        self.clearsSelectionOnViewWillAppear = true
        tableView.tableFooterView = UIView()
        
        picker.delegate = self
        picker.dataSource = self
        
        ageTextField.keyboardType = .numberPad
        chestPainTextField.inputView = picker
        bpTextField.keyboardType = .numberPad
        bloodSugarTextField.keyboardType = .numberPad
        electroTextField.inputView = picker
        heartRateTextField.keyboardType = .numberPad
        exerciseTextField.inputView = picker
    }

    @IBAction func predict(_ sender: Any) {
        self.view.endEditing(true)
        let prediction = self.updatePredictedResult()
        outputLabel.text = prediction > 0 ? "NEGATIVE" : "POSITIVE"
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }
    
    // MARK: - Textfield Delegate
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === self.chestPainTextField {
            selectedRow = Row.chestPain
        } else if textField === self.electroTextField {
            selectedRow = Row.electro
        } else if textField === self.exerciseTextField {
            selectedRow = Row.exercise
        }
        return true
    }
    
    // MARK: - Picker view data source and delegate
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let rowType = self.selectedRow else { return 0 }
        switch rowType {
        case .age, .bloodPressure, .bloodSugar, .heartRate:
            return 0
        case .chestPain:
            return self.chestPainOptions.count
        case .electro:
            return self.electroOptions.count
        case .exercise:
            return self.exerciseOptions.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        guard let rowType = self.selectedRow else { return nil }
        switch rowType {
        case .age, .bloodPressure, .bloodSugar, .heartRate:
            return nil
        case .chestPain:
            return self.chestPainOptions[row]
        case .electro:
            return self.electroOptions[row]
        case .exercise:
            return self.exerciseOptions[row]
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let rowType = self.selectedRow else { return }
        switch rowType {
        case .age, .bloodPressure, .bloodSugar, .heartRate:
            break
        case .chestPain:
            self.chestPainTextField.text = self.chestPainOptions[row]
        case .electro:
            self.electroTextField.text = self.electroOptions[row]
        case .exercise:
            self.exerciseTextField.text = self.exerciseOptions[row]
        }
        self.view.endEditing(true)
    }
    
    /**
     The main logic for the app, performing the integration with Core ML.
     First gather the values for input to the model. Then have the model generate
     a prediction with those inputs. Finally, present the predicted value to
     the user.
    */
    func updatePredictedResult() -> (Double) {
        let age = ageTextField.text ?? "20"
        let chest_pain_asympt = chestPainTextField.text == "chest_pain_asympt" ? Double(1) : Double(0)
        let chest_pain_atyp_angina = chestPainTextField.text == "chest_pain_atyp_angina" ? Double(1) : Double(0)
        let chest_pain_non_anginal = chestPainTextField.text == "chest_pain_non_anginal" ? Double(1) : Double(0)
        let chest_pain_typ_angina = chestPainTextField.text == "chest_pain_typ_angina" ? Double(1) : Double(0)
        let rest_bpress = bpTextField.text ?? "120"
        let blood_sugar = bloodSugarTextField.text ?? "100"
        let rest_electro_left_vent_hyper = electroTextField.text == "rest_electro_left_vent_hyper" ? Double(1) : Double(0)
        let rest_electro_normal = electroTextField.text == "rest_electro_normal" ? Double(1) : Double(0)
        let rest_electro_st_t_wave_abnormality = electroTextField.text == "rest_electro_st_t_wave_abnormality" ? Double(1) : Double(0)
        let max_heart_rate = heartRateTextField.text ?? "100"
        let exercice_angina = exerciseTextField.text == "YES" ? Double(1) : Double(0)
        
        guard let output = try? self.predictorModel.prediction(age: Double(age)!,
                                                               chest_pain_asympt: chest_pain_asympt,
                                                               chest_pain_atyp_angina: chest_pain_atyp_angina,
                                                               chest_pain_non_anginal: chest_pain_non_anginal,
                                                               chest_pain_typ_angina: chest_pain_typ_angina,
                                                               rest_bpress: Double(rest_bpress)!,
                                                               blood_sugar: Double(blood_sugar)!,
                                                               rest_electro_left_vent_hyper: rest_electro_left_vent_hyper,
                                                               rest_electro_normal: rest_electro_normal,
                                                               rest_electro_st_t_wave_abnormality: rest_electro_st_t_wave_abnormality,
                                                               max_heart_rate: Double(max_heart_rate)!,
                                                               exercice_angina: exercice_angina) else {
            fatalError("Unexpected runtime error.")
        }
        
        print("Prediction: \(output.disease)")
        return output.disease
    }

}
