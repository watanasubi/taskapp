//
//  ViewController.swift
//  taskapp
//
//  Created by 加来　航 on 2021/09/03.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
   
    
    // テーブルビュー
    @IBOutlet weak var tableView: UITableView!
    
    //検索用
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する
       let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
      // 日付の近い順でソート：昇順
      // 以降内容をアップデートするとリスト内は自動的に更新される。
      var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // テーブルを本クラスへ移譲
        tableView.delegate = self
        //データーソースを本クラスへ移譲
        tableView.dataSource = self
        //検索バーを本クラスへ移譲
        searchBar.delegate = self
        // 検索バー入力時に1文字目が大文字に変換されないようにする
        searchBar.autocapitalizationType = .none
        // 検索バー入力時の自動補正を無効にする
        searchBar.autocorrectionType = .no
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

          // 検索キーワードが空のとき
          if searchText.isEmpty {
              // レルムの全データを日付の昇順で取得
              taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
          // 検索キーワードが入っているとき
          }else{
              // レルムのデータを検索キーワードで絞り込みして日付の昇順で取得
              taskArray = try! Realm().objects(Task.self).filter("category = '\(searchText)'").sorted(byKeyPath: "date", ascending: true)
          }

          // テーブル再表示
          tableView.reloadData()
      }
    
    //データの数（セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    //各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->UITableViewCell{
        
        //再利用可能なcellを得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
  
        // Cellに値を設定する
        let task = taskArray[indexPath.row]
        
        //タイトルをセルへ
        cell.textLabel?.text = task.title
        
        //日付のフォーマットをセット
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"

        //日付をセルへ
                let dateString:String = formatter.string(from: task.date)
                cell.detailTextLabel?.text = dateString
        
       return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            //segueのIDを指定して画面遷移
        performSegue(withIdentifier: "cellSegue", sender: nil)
        }

        // セルが削除が可能なことを伝えるメソッド
        func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
            return .delete
        }

        // Delete ボタンが押された時に呼ばれるメソッド
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            
                 //編集パターンが削除可能なら
                  if editingStyle == .delete {
                      // 削除するタスクを取得する
                      let task = self.taskArray[indexPath.row]

                      // ローカル通知をキャンセルする
                      let center = UNUserNotificationCenter.current()
                      center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

                      // データベースから削除する
                      try! realm.write {
                          self.realm.delete(task)
                          //　テーブルビューからも削除
                          tableView.deleteRows(at: [indexPath], with: .fade)
                      }

                      // 未通知のローカル通知一覧をログ出力
                      center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                          for request in requests {
                              print("/---------------")
                              print(request)
                              print("---------------/")
                          }
                      }
                  }
        }
    
    
    // segue で画面遷移する時に呼ばれる
        override func prepare(for segue: UIStoryboardSegue, sender: Any?){
            
            //　次画面のインスタンス取得
            let inputViewController:inputViewController = segue.destination as! inputViewController

            //　セルが押された場合
            if segue.identifier == "cellSegue" {
                
                // 選択行を取得
                let indexPath = self.tableView.indexPathForSelectedRow
                
                //　次画面に選択行のデータを渡す
                inputViewController.task = taskArray[indexPath!.row]
                
                //　＋が押された場合
            } else {
                
                // タスク新規登録用インスタンス生成
                let task = Task()

                //　Realm全データを取得
                let allTasks = realm.objects(Task.self)
                
                //　データが存在する場合
                if allTasks.count != 0 {
                    // 最後のID＋1を新規登録用IDとする
                    task.id = allTasks.max(ofProperty: "id")! + 1
                }

                inputViewController.task = task
            }
        }
   
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //テーブルビューを更新する
        tableView.reloadData()
    }
    
}

