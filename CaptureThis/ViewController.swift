//
//  ViewController.swift
//  CaptureThis
//
//  Created by Andrei Korikov on 29.10.2021.
//

import UIKit

class ViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var items = [Item]()
    let itemsUDKey = "items"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addImage))
        toolbarItems = [spaceItem, addItem, spaceItem]
        
        if let dataItems = UserDefaults.standard.object(forKey: itemsUDKey) as? Data {
            items = (try? PropertyListDecoder().decode([Item].self, from: dataItems)) ?? [Item]()
        }
    }
    
    @objc func addImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        }
        present(imagePicker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        
        let item = Item(image: imageName, description: nil)
        items.append(item)
        
        dismiss(animated: true, completion: showDescDialog)
    }
    
    func showDescDialog() {
        let ac = UIAlertController(title: "Type description text:", message: nil, preferredStyle: .alert)
        ac.addTextField()
        ac.addAction(UIAlertAction(title: "OK", style: .default) { [unowned ac, weak self] _ in
            let description = ac.textFields?[0].text ?? ""
            
            let lastIndex = (self?.items.endIndex)! - 1
            self?.items[lastIndex].description = description
            
            let index = IndexPath(row: lastIndex, section: 0)
            self?.tableView.insertRows(at: [index], with: .automatic)
            
            self?.save()
        })
        
        present(ac, animated: true)
    }
    
    func save() {
        if let encodedItems = try? PropertyListEncoder().encode(items) {
            UserDefaults.standard.set(encodedItems, forKey: itemsUDKey)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImageRow", for: indexPath)
        
        let item = items[indexPath.row]
        cell.textLabel?.text = item.description
        
        let path = getDocumentsDirectory().appendingPathComponent(item.image)
        cell.imageView?.image = UIImage(contentsOfFile: path.path)
        
        cell.imageView?.layer.borderColor = UIColor(white: 0, alpha: 0.3).cgColor
        cell.imageView?.layer.borderWidth = 2
        cell.imageView?.layer.cornerRadius = 3
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "DetailVC") as? DetailViewController {
            // 2: success! Set its selectedImage property
            let item = items[indexPath.row]
            let imageName = item.image
            let imagePath = getDocumentsDirectory().appendingPathComponent(imageName).path
            vc.imagePath = imagePath
            vc.title = item.description
            
            // 3: now push it onto the navigation controller
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
