import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {

    var itemPlayer: AVAudioPlayer! = nil //再生するサウンドのインスタンス
    
    var scrollNode:SKNode!
    var wallNode:SKNode!    // 追加
    var bird:SKSpriteNode!
    var itemNode:SKNode!

    // 衝突判定カテゴリー ↓追加
      let birdCategory: UInt32 = 1 << 0       // 0...00001
      let groundCategory: UInt32 = 1 << 1     // 0...00010
      let wallCategory: UInt32 = 1 << 2       // 0...00100
      let scoreCategory: UInt32 = 1 << 3      // 0...01000
    let itemScoreCategory: UInt32 = 1 << 4

      // スコア用
    var score = 0  // ←追加
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    let userDefaults:UserDefaults = UserDefaults.standard


      // SKView上にシーンが表示されたときに呼ばれるメソッド
    override func didMove(to view: SKView) {
        // 再生する音声ファイルを指定する
        let itemSoundURL = Bundle.main.url(forResource: "ItemGetSound", withExtension: "mp3")
        do {
            // 効果音を鳴らす
            itemPlayer = try AVAudioPlayer(contentsOf: itemSoundURL!)
        } catch {
            print("error...")
        }
//        重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        physicsWorld.contactDelegate = self
        // 背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)

        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)

//        壁用のノード 追下
        wallNode = SKNode()
        scrollNode.addChild(wallNode)

        //アイテム用のノード
        itemNode = SKNode()
        scrollNode.addChild(itemNode)   //scrollNodeに追加
        //        各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()

//        スコア表示ラベルの設定
        setupScoreLabel()
    }


        func setupGround(){
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)

        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))

        // groundのスプライトを配置する
        for i in 0..<needNumber {
            let sprite = SKSpriteNode(texture: groundTexture)

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2  + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2
            )

            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)

            // スプライトに物理体を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())   // ←追加

            // 衝突のカテゴリー設定
                                    sprite.physicsBody?.categoryBitMask = groundCategory    // ←追加

            // 衝突の時に動かないように設定する
            sprite.physicsBody?.isDynamic = false   // ←追加



            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupCloud() {
        // 雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest

        // 必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2

        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)

        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)

        // 左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))

        // スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろになるようにする

            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2
            )

            // スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)

            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }

    func setupWall() {
            // 壁の画像を読み込む
            let wallTexture = SKTexture(imageNamed: "wall")
            wallTexture.filteringMode = .linear

            // 移動する距離を計算
            let movingDistance = self.frame.size.width + wallTexture.size().width

            // 画面外まで移動するアクションを作成
            let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration:4)

            // 自身を取り除くアクションを作成
            let removeWall = SKAction.removeFromParent()

            // 2つのアニメーションを順に実行するアクションを作成
            let wallAnimation = SKAction.sequence([moveWall, removeWall])

            // 鳥の画像サイズを取得
            let birdSize = SKTexture(imageNamed: "bird_a").size()

            // 鳥が通り抜ける隙間の大きさを鳥のサイズの4倍とする
            let slit_length = birdSize.height * 4

            // 隙間位置の上下の振れ幅を60ptとする
            let random_y_range: CGFloat = 60

            // 空の中央位置(y座標)を取得
            let groundSize = SKTexture(imageNamed: "ground").size()
            let sky_center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2

            // 空の中央位置を基準にして下側の壁の中央位置を取得
            let under_wall_center_y = sky_center_y - slit_length / 2 - wallTexture.size().height / 2

            // 壁を生成するアクションを作成
            let createWallAnimation = SKAction.run({
                // 壁をまとめるノードを作成
                let wall = SKNode()
                wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
                wall.zPosition = -50 // 雲より手前、地面より奥

                // 下側の壁の中央位置にランダム値を足して、下側の壁の表示位置を決定する
                let random_y = CGFloat.random(in: -random_y_range...random_y_range)
                let under_wall_y = under_wall_center_y + random_y

                // 下側の壁を作成
                let under = SKSpriteNode(texture: wallTexture)
                under.position = CGPoint(x: 0, y: under_wall_y)

                // 下側の壁に物理体を設定する
                under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())    // ←追加
                under.physicsBody?.categoryBitMask = self.wallCategory
                under.physicsBody?.isDynamic = false

                // 壁をまとめるノードに下側の壁を追加
                wall.addChild(under)

                // 上側の壁を作成
                let upper = SKSpriteNode(texture: wallTexture)
                upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)

                // 上側の壁に物理体を設定する
                upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())    // ←追加
                upper.physicsBody?.categoryBitMask = self.wallCategory
                upper.physicsBody?.isDynamic = false    // ←追加

                // 壁をまとめるノードに上側の壁を追加
                wall.addChild(upper)


                // --- ここから ---
                // スコアカウント用の透明な壁を作成
                let scoreNode = SKNode()
                scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.height / 2)
                // 透明な壁に物理体を設定する
                scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
                scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
                scoreNode.physicsBody?.isDynamic = false
                // 壁をまとめるノードに透明な壁を追加
                wall.addChild(scoreNode)
                // --- ここまで追加 ---

                // 壁をまとめるノードにアニメーションを設定
                wall.run(wallAnimation)

                // 壁を表示するノードに今回作成した壁を追加
                self.wallNode.addChild(wall)
            })
            // 次の壁作成までの時間待ちのアクションを作成
            let waitAnimation = SKAction.wait(forDuration: 2)

            // 壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
            let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))

            // // 壁を表示するノードに壁の作成を無限に繰り返すアクションを設定
            wallNode.run(repeatForeverAnimation)
        }

    func setupBird(){

        // 鳥の画像を2種類読み込む
                let birdTextureA = SKTexture(imageNamed: "bird_a")
                birdTextureA.filteringMode = .linear
                let birdTextureB = SKTexture(imageNamed: "bird_b")
                birdTextureB.filteringMode = .linear

                // 2種類のテクスチャを交互に変更するアニメーションを作成
                let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
                let flap = SKAction.repeatForever(texturesAnimation)

                // スプライトを作成
                bird = SKSpriteNode(texture: birdTextureA)
                bird.position = CGPoint(x: self.frame.size.width * 0.2, y:self.frame.size.height * 0.7)

//        物理体を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)

        // カテゴリー設定
              bird.physicsBody?.categoryBitMask = birdCategory    // ←追加
              bird.physicsBody?.collisionBitMask = groundCategory | wallCategory    // ←追加
              bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory | scoreCategory    // ←追加

              // 衝突した時に回転させない
              bird.physicsBody?.allowsRotation = false    // ←追加

        // アニメーションを設定
                bird.run(flap)

                // スプライトを追加する
                addChild(bird)
    }
    
    
    func setupItem() {
        //アイテムの画像を読み込む
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width * 2)
        
        // 画面外まで移動するアクションを作成
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
        
        // 自身を取り除くアクションを作成
        let removeItem = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let itemAnimation = SKAction.sequence([moveItem, removeItem])
        
        // アイテムを生成するアクションを作成
        let createItemAnimation = SKAction.run ({
            // アイテム関連のノードをのせるノードを作成
            let item = SKNode()
            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
            
            // 画面のY軸の中央値
            let center_y = (self.frame.size.height / 2)
            // アイテムのY座標を上下ランダムにさせるときの最大値
            let random_y_range = (self.frame.size.height / 2)
            // アイテムのY軸の下限UInt32( center_y - itemTexture.size().height / 2 -  random_y_range / 2)
            
            let item_lowest_y = UInt32(center_y - itemTexture.size().height / 2 -  random_y_range / 2)
            
            
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform( UInt32(random_y_range) )
            // Y軸の下限にランダムな値を足して、アイテムのY座標を決定
            let item_y = CGFloat(UInt32(item_lowest_y) + random_y)
            
            // 画面のx軸の中央値
            let center_x = self.frame.size.width / 2
            // アイテムのX座標を上下ランダムにさせるときの最大値
            let random_x_range = self.frame.size.width / 2
            // アイテムのX軸の下限
            let item_lowest_x = UInt32( center_x - itemTexture.size().width / 2 -  random_x_range / 2)
            // 1〜random_x_rangeまでのランダムな整数を生成
            let random_x = arc4random_uniform( UInt32(random_x_range) )
            // X軸の下限にランダムな値を足して、アイテムのX座標を決定
            let item_x = CGFloat(item_lowest_x + random_x)
            
            //アイテムを生成
            let itemSprite = SKSpriteNode(texture: itemTexture)
            itemSprite.position = CGPoint(x: item_x, y: item_y)

            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))//重力を設定
            itemSprite.physicsBody?.isDynamic = false
            itemSprite.physicsBody?.categoryBitMask = self.itemScoreCategory
            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory   //衝突判定させる相手のカテゴリを設定
            
            item.addChild(itemSprite)
            
            item.run(itemAnimation)
            
            self.itemNode.addChild(item)
            
        })
        // 次のアイテム作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
        
        itemNode.run(repeatForeverAnimation)
        
    }
    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100 // 一番手前に表示する
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item Score:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
        // 鳥の速度をゼロにする
        bird.physicsBody?.velocity = CGVector.zero

        // 鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        } else if bird.speed == 0 {
            restart()
        }
    }

    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーのときは何もしない
        if scrollNode.speed <= 0 {
            return
        }

        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコア更新か確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
            }
            
        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
            //アイテムに衝突した
            print("ItemGet")
            itemScore += 1
            itemScoreLabelNode.text = "Item Score:\(itemScore)"
            
            itemPlayer?.play()
            
            if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyA.node?.removeFromParent()
            }
            if (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
                contact.bodyB.node?.removeFromParent()
            }
            
        } else {
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            //回転させて、回転が終わった時に鳥のスピードも0にする
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
        }
        
    }
    

    func restart() {
            // スコアを0にする
        score = 0
        scoreLabelNode.text = String("Score:\(score)")
        
        itemScore = 0
        itemScoreLabelNode.text = String("Item Score:\(itemScore)")
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
}
//  GameScene.swift
//  FlappyBird
//
//  Created by 鈴木健太 on 2022/08/22.
//

//import SpriteKit
//import AVFoundation
//
//class GameScene: SKScene, SKPhysicsContactDelegate {
//
//    var itemPlayer: AVAudioPlayer! = nil //再生するサウンドのインスタンス
//
//    var scrollNode:SKNode!
//    var wallNode:SKNode!
//    var bird:SKSpriteNode!
//    var itemNode:SKNode!
//
//    //衝突判定カテゴリ
//    let birdCategory: UInt32 = 1 << 0   // 0...00001
//    let groundCategory: UInt32 = 1 << 1 // 0...00010
//    let wallCategory: UInt32 = 1 << 2   // 0...00100
//    let scoreCategory: UInt32 = 1 << 3  // 0...01000
//    let itemScoreCategory: UInt32 = 1 << 4
//
//    //スコア
//    var score = 0
//    var itemScore = 0
//    var scoreLabelNode:SKLabelNode!
//    var bestScoreLabelNode:SKLabelNode!
//    var itemScoreLabelNode:SKLabelNode!
//    let userDefaults:UserDefaults = UserDefaults.standard
//
//    //SKView上にシーンが表示された時に呼ばれるメソッド
//    override func didMove(to view: SKView) {
//        // 再生する音声ファイルを指定する
//        let itemSoundURL = Bundle.main.url(forResource: "ItemGetSound", withExtension: "mp3")
//        do {
//            // 効果音を鳴らす
//            itemPlayer = try AVAudioPlayer(contentsOf: itemSoundURL!)
//        } catch {
//            print("error...")
//        }
//
//
//        //重力を設定
//        physicsWorld.gravity = CGVector(dx: 0.0, dy: -4.0)
//        physicsWorld.contactDelegate = self
//
//        //背景色を設定(今回は青色)
//        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
//
//        //スクロールするスプライトの親ノード
//        scrollNode = SKNode()
//        addChild(scrollNode)
//
//        //壁用のノード
//        wallNode = SKNode()
//        scrollNode.addChild(wallNode) //scrollNodeに追加
//
//        //アイテム用のノード
//        itemNode = SKNode()
//        scrollNode.addChild(itemNode)   //scrollNodeに追加
//
//
//        //各種スプライトを生成する処理をメソッドに分割
//        setupGround()
//        setupCloud()
//        setupWall()
//        setupBird()
//        setupItem()
//
//        setupScoreLabel()
//    }
//
//    func setupGround() {
//
//        //地面の画像を読み込む
//        let groundTexture = SKTexture(imageNamed: "ground")
//        groundTexture.filteringMode = .nearest
//
//        //必要な枚数を計算
//        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
//
//        //スクロールするアクションを作成
//        //左方向に画像一枚分スクロールすさせるアクション
//        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
//
//        //元の位置に戻すアクション
//        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
//
//        //左にスクロール->元の位置->左にスクロールと無限に繰り返すアクション
//        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
//
//        //groundのスプライトを配置する
//        for i in 0..<needNumber {
//            //テクスチャ作成
//            let sprite = SKSpriteNode(texture: groundTexture)
//
//            //スプライトの表示する位置を指定する
//            sprite.position = CGPoint(
//                x: groundTexture.size().width * (CGFloat(i) + 0.5),
//                y: groundTexture.size().height * 0.5
//            )
//
//            //スプライトにアクションを設定する
//            sprite.run(repeatScrollGround)
//
//            //スプライトに物理演算を設定する
//            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
//
//
//            //衝突のカテゴリ設定
//            sprite.physicsBody?.categoryBitMask = groundCategory
//
//            //衝突の時に動かないように設定する
//            sprite.physicsBody?.isDynamic = false
//
//            //スプライトを追加する
//            scrollNode.addChild(sprite)
//        }
//
//    }
//
//    func setupCloud() {
//        //蜘蛛の画像を読み込む
//        let cloudTexture = SKTexture(imageNamed: "cloud")
//        cloudTexture.filteringMode = .nearest
//
//        //必要な枚数を計算
//        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
//
//        // スクロールするアクションを作成
//        // 左方向に画像一枚分スクロールさせるアクション
//        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
//
//        //元の位置に戻すアクション
//        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
//
//        // 左にスクロール->元の位置->左にスクロールと無限に繰り替えるアクション
//        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
//
//        //スプライトを配置する
//        for i in 0..<needCloudNumber {
//            let sprite = SKSpriteNode(texture: cloudTexture)
//            sprite.zPosition = -100  //一番後ろに雲が配置されるようにする
//
//            //スプライトの表示する位置を指定する
//            sprite.position = CGPoint(
//                x: cloudTexture.size().width * (CGFloat(i) + 0.5),
//                y: self.size.height - cloudTexture.size().height * 0.5
//            )
//
//            //スプライトにアニメーションを設定する
//            sprite.run(repeatScrollCloud)
//
//            // スプライトを追加する
//            scrollNode.addChild(sprite)
//        }
//    }
//
//    func setupWall() {
//        //壁の画像を読み込む
//        let wallTexture = SKTexture(imageNamed: "wall")
//        wallTexture.filteringMode = .linear
//
//        //移動する距離を計算
//        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
//
//        //画面外まで移動するアクションを作成
//        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
//
//        //自信を取り除くアクションを作成
//        let removeWall = SKAction.removeFromParent()
//
//        //二つのアニメーションを順に実行するアクション
//        let wallAnimation = SKAction.sequence([moveWall, removeWall])
//
//        //壁を生成するアクションを作成
//        let creatingWallAnimation = SKAction.run ({
//            //壁関連のノードをのせるノードを作成
//            let wall = SKNode()
//            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
//            wall.zPosition = -50.0 //雲より手前で地面より奥
//
//            //画面のy軸の中央値
//            let center_y = self.frame.size.height / 2
//            //壁のy座標を上下ランダムにさせる時の最大値
//            let random_y_range = self.frame.size.height / 4
//            //下の壁のy軸の下限
//            let under_wall_lowest_y = UInt32( center_y - wallTexture.size().height / 2 -  random_y_range / 2)
//            //1~random_y_rangeまでのランダムな整数を生成
//            let random_y = arc4random_uniform( UInt32(random_y_range))
//            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
//            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
//
//            //キャラが通り抜ける隙間の長さ
//            let slit_length = self.frame.size.height / 6
//
//            //下側の壁を生成
//            let under = SKSpriteNode(texture: wallTexture)
//            under.position = CGPoint(x: 0.0, y: under_wall_y)
//
//            //スプライトに物理演算を設定する
//            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
//            under.physicsBody?.categoryBitMask = self.wallCategory  //壁にカテゴリを設定する
//            //衝突の時に動かないようにする
//            under.physicsBody?.isDynamic = false
//
//            wall.addChild(under)
//
//            //上側の壁を生成
//            let upper = SKSpriteNode(texture: wallTexture)
//            upper.position = CGPoint(x:0.0, y: under_wall_y + wallTexture.size().height + slit_length)
//
//            //スプライトに物理演算を設定する
//            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
//            upper.physicsBody?.categoryBitMask = self.wallCategory  //壁にカテゴリを設定する
//            //衝突の時動かないようにする
//            upper.physicsBody?.isDynamic = false
//
//            wall.addChild(upper)
//
//            // スコアアップ用のノード
//            let scoreNode = SKNode()
//            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.height / 2.0)
//            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))  //重力を設定
//            scoreNode.physicsBody?.isDynamic = false
//            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
//            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory   //衝突判定させる相手のカテゴリを設定
//
//            wall.addChild(scoreNode)
//
//            wall.run(wallAnimation)
//
//            self.wallNode.addChild(wall)
//        })
//
//        //次の壁作成までの待ち時間のアクションを生成
//        let waitAnimation = SKAction.wait(forDuration: 3.5)
//
//        // 壁を作成->待ち時間->壁を作成を無限に繰り替えるアクションを作成
//        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([creatingWallAnimation, waitAnimation]))
//
//        wallNode.run(repeatForeverAnimation)
//    }
//
//    func setupBird() {
//        //鳥の画像を二種類読み込む
//        let birdTextureA = SKTexture(imageNamed: "bird_a")
//        birdTextureA.filteringMode = .linear
//        let birdTextureB = SKTexture(imageNamed: "bird_b")
//        birdTextureB.filteringMode = .linear
//
//        //二種類のテクスチャを交互に変更するアニメーションを作成
//        let textureAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.2)
//        let flap = SKAction.repeatForever(textureAnimation)
//
//        //スプライトを作成
//        bird = SKSpriteNode(texture: birdTextureA)
//        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
//
//        //物理演算を設定
//        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
//
//        //衝突したときに回転させない
//        bird.physicsBody?.allowsRotation = false
//
//        //衝突のカテゴリ設定
//        bird.physicsBody?.categoryBitMask = birdCategory    //自身のカテゴリを設定
//        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory  //衝突した時跳ね返る動作をする相手のカテゴリを設定
//        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory  //衝突する相手のカテゴリを設定
//
//        //アニメーションを設定
//        bird.run(flap)
//
//        //スプライトを追加する
//        addChild(bird)
//    }
//
//    func setupItem() {
//        //アイテムの画像を読み込む
//        let itemTexture = SKTexture(imageNamed: "item")
//        itemTexture.filteringMode = .linear
//
//        //移動する距離を計算
//        let movingDistance = CGFloat(self.frame.size.width * 2)
//
//        // 画面外まで移動するアクションを作成
//        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration:4.0)
//
//        // 自身を取り除くアクションを作成
//        let removeItem = SKAction.removeFromParent()
//
//        // 2つのアニメーションを順に実行するアクションを作成
//        let itemAnimation = SKAction.sequence([moveItem, removeItem])
//
//        // アイテムを生成するアクションを作成
//        let createItemAnimation = SKAction.run ({
//            // アイテム関連のノードをのせるノードを作成
//            let item = SKNode()
//            item.position = CGPoint(x: self.frame.size.width + itemTexture.size().width / 2, y: 0.0)
//
//            // 画面のY軸の中央値
//            let center_y = (self.frame.size.height / 2)
//            // アイテムのY座標を上下ランダムにさせるときの最大値
//            let random_y_range = (self.frame.size.height / 2)
//            // アイテムのY軸の下限UInt32( center_y - itemTexture.size().height / 2 -  random_y_range / 2)
//
//            let item_lowest_y = UInt32(center_y - itemTexture.size().height / 2 -  random_y_range / 2)
//
//
//            // 1〜random_y_rangeまでのランダムな整数を生成
//            let random_y = arc4random_uniform( UInt32(random_y_range) )
//            // Y軸の下限にランダムな値を足して、アイテムのY座標を決定
//            let item_y = CGFloat(UInt32(item_lowest_y) + random_y)
//
//            // 画面のx軸の中央値
//            let center_x = self.frame.size.width / 2
//            // アイテムのX座標を上下ランダムにさせるときの最大値
//            let random_x_range = self.frame.size.width / 2
//            // アイテムのX軸の下限
//            let item_lowest_x = UInt32( center_x - itemTexture.size().width / 2 -  random_x_range / 2)
//            // 1〜random_x_rangeまでのランダムな整数を生成
//            let random_x = arc4random_uniform( UInt32(random_x_range) )
//            // X軸の下限にランダムな値を足して、アイテムのX座標を決定
//            let item_x = CGFloat(item_lowest_x + random_x)
//
//            //アイテムを生成
//            let itemSprite = SKSpriteNode(texture: itemTexture)
//            itemSprite.position = CGPoint(x: item_x, y: item_y)
//
//            itemSprite.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: itemSprite.size.width, height: itemSprite.size.height))//重力を設定
//            itemSprite.physicsBody?.isDynamic = false
//            itemSprite.physicsBody?.categoryBitMask = self.itemScoreCategory
//            itemSprite.physicsBody?.contactTestBitMask = self.birdCategory   //衝突判定させる相手のカテゴリを設定
//
//            item.addChild(itemSprite)
//
//            item.run(itemAnimation)
//
//            self.itemNode.addChild(item)
//
//        })
//        // 次のアイテム作成までの待ち時間のアクションを作成
//        let waitAnimation = SKAction.wait(forDuration: 2)
//
//        // アイテムを作成->待ち時間->アイテムを作成を無限に繰り替えるアクションを作成
//        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation, waitAnimation]))
//
//        itemNode.run(repeatForeverAnimation)
//
//    }
//
//    func setupScoreLabel() {
//        score = 0
//        scoreLabelNode = SKLabelNode()
//        scoreLabelNode.fontColor = UIColor.black
//        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
//        scoreLabelNode.zPosition = 100 // 一番手前に表示する
//        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
//        scoreLabelNode.text = "Score:\(score)"
//        self.addChild(scoreLabelNode)
//
//        bestScoreLabelNode = SKLabelNode()
//        bestScoreLabelNode.fontColor = UIColor.black
//        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
//        bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
//        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
//
//        let bestScore = userDefaults.integer(forKey: "BEST")
//        bestScoreLabelNode.text = "Best Score:\(bestScore)"
//        self.addChild(bestScoreLabelNode)
//
//        itemScore = 0
//        itemScoreLabelNode = SKLabelNode()
//        itemScoreLabelNode.fontColor = UIColor.black
//        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 120)
//        itemScoreLabelNode.zPosition = 100 // 一番手前に表示する
//        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
//        itemScoreLabelNode.text = "Item Score:\(itemScore)"
//        self.addChild(itemScoreLabelNode)
//    }
//
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//
//        if scrollNode.speed > 0 {   //つまり、ゲーム中の時には
//
//            //鳥の速度を0にする
//            bird.physicsBody?.velocity = CGVector.zero
//
//            //鳥に縦方向の力を与える
//            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
//        } else if bird.speed == 0 {
//            restart()
//        }
//    }
//
//    // SKPhysicsContactDelegateのメソッド。衝突したときに呼ばれる
//    func didBegin(_ contact: SKPhysicsContact) {
//        //ゲームオーバーの時は何もしない
//        if scrollNode.speed <= 0 {
//            return
//        }
//
//        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
//            //スコア用の物体と衝突した
//            print("ScoreUp")
//            score += 1
//            scoreLabelNode.text = "Score:\(score)"
//
//            // ベストスコア更新か確認する
//            var bestScore = userDefaults.integer(forKey: "BEST")
//            if score > bestScore {
//                bestScore = score
//                bestScoreLabelNode.text = "Best Score:\(bestScore)"
//                userDefaults.set(bestScore, forKey: "BEST")
//                userDefaults.synchronize()
//            }
//
//        } else if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory || (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
//            //アイテムに衝突した
//            print("ItemGet")
//            itemScore += 1
//            itemScoreLabelNode.text = "Item Score:\(itemScore)"
//
//            itemPlayer?.play()
//
//            if (contact.bodyA.categoryBitMask & itemScoreCategory) == itemScoreCategory {
//                contact.bodyA.node?.removeFromParent()
//            }
//            if (contact.bodyB.categoryBitMask & itemScoreCategory) == itemScoreCategory {
//                contact.bodyB.node?.removeFromParent()
//            }
//
//        } else {
//            //壁か地面と衝突した
//            print("GameOver")
//
//            //スクロールを停止させる
//            scrollNode.speed = 0
//
//            bird.physicsBody?.collisionBitMask = groundCategory
//
//            //回転させて、回転が終わった時に鳥のスピードも0にする
//            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
//            bird.run(roll, completion: {
//                self.bird.speed = 0
//            })
//        }
//
//
//    }
//
//    func restart() {
//
//
//        score = 0
//        scoreLabelNode.text = String("Score:\(score)")
//
//        itemScore = 0
//        itemScoreLabelNode.text = String("Item Score:\(itemScore)")
//
//        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
//        bird.physicsBody?.velocity = CGVector.zero
//        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
//        bird.zRotation = 0.0
//
//        wallNode.removeAllChildren()
//
//        bird.speed = 1
//        scrollNode.speed = 1
//    }
//}





//    func setupScoreLabel() {
//         // スコア表示を作成
//         score = 0
//         scoreLabelNode = SKLabelNode()
//         scoreLabelNode.fontColor = UIColor.black
//         scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
//         scoreLabelNode.zPosition = 100 // 一番手前に表示する
//         scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
//         scoreLabelNode.text = "Score:\(score)"
//         self.addChild(scoreLabelNode)
//
//         // ベストスコア表示を作成
//         let bestScore = userDefaults.integer(forKey: "BEST")
//         bestScoreLabelNode = SKLabelNode()
//         bestScoreLabelNode.fontColor = UIColor.black
//         bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
//         bestScoreLabelNode.zPosition = 100 // 一番手前に表示する
//         bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
//         bestScoreLabelNode.text = "Best Score:\(bestScore)"
//         self.addChild(bestScoreLabelNode)
//     }
//
//}




//class GameScene: SKScene {
//
//    var scrollNode: SKNode!
//
//    // SKView上にシーンが表示されたときに呼ばれるメソッド
////    ゲーム画面（＝SKSceneクラスを継承したクラス）が表示されるときに呼ばれるメソッドがdidMove(to:)メソッドになります。このメソッドで画面を構築する処理を書いたり、ゲームの初期設定を行います。
//    override func didMove(to view: SKView) {
//        // 背景色を設定
//        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
////        スクロールするスプライト（キャラクターや地面などの画像）の親ノード
//        scrollNode = SKNode()
//        addChild(scrollNode)
////        キャラクターや地面などの画像を表示するためのもの　（スプライト）
////        SpriteKitでは表示する画像をSKTextureで扱うという認識で大丈夫
//        // 地面の画像を読み込む　画像のファイル名を指定して作成
//               let groundTexture = SKTexture(imageNamed: "ground")
//        //        nearestで画像が荒くなるが処理が早い　.linearで画像が綺麗だが処理が遅い
//               groundTexture.filteringMode = .nearest
//        //        必要な枚数を計算
//        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
////        スクロールするアクションを作成　左方向に画像一枚分スクロールさせるアクション
//        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
////        元の位置に戻すアクション
//        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
////        左にスクロール　元の位置　んで左にスクロールのように無限に繰り返すアクション
//        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
////        groundのスプライトを配置
//        for i in 0..<needNumber {
//            let sprite = SKSpriteNode(texture: groundTexture)
////            スプライトの表示する位置を指定する
//            sprite.position = CGPoint(x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i), y: groundTexture.size().height / 2
//            )
//        }
//
//
//               // テクスチャを指定してスプライトを作成する
//               let groundSprite = SKSpriteNode(texture: groundTexture)
//
//               // スプライトの表示する位置を指定する
//               groundSprite.position = CGPoint(
//                   x: groundTexture.size().width / 2,
//                   y: groundTexture.size().height / 2
//               )
//
//               // シーンにスプライトを追加する
//               addChild(groundSprite)
//
//    }
//}


