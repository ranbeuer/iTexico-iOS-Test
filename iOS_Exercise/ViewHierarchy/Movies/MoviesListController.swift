//
//  ViewController.swift
//  iOS_Exercise
//
//  Created by Giovani Gonzalez on 2/28/19.
//  Copyright © 2019 iTexico. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import SVProgressHUD

class MoviesListController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView?

    private lazy var viewModel: MoviesViewModel = {
        return MoviesViewModel()
    }()
    
    private var movies = [Movie]()
    private var cellSize = CGSize.zero
    var gettingMore: Bool = true
    var cellWidth: CGFloat = 0
    var selectedMovie: Movie!
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            let device = UIDevice.current.userInterfaceIdiom
            if (device == .pad) {
                return .all
            }
            return .portrait
        }
    }
    
    override var shouldAutorotate: Bool {
        let device = UIDevice.current.userInterfaceIdiom
        return device == .pad
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.dataSource = self
        collectionView?.delegate = self
//        collectionView?.register(MoviesCollectionViewCell.self, forCellWithReuseIdentifier: MoviesCollectionViewCell.identifier)
        setUpVM()
        self.navigationController?.hidesBarsOnSwipe = true
        self.title = "PopularMovies".localized()
        
        let width = self.view.frame.size.width
        cellWidth = width / (UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2)
        let topBar = UIView(frame: UIApplication.shared.statusBarFrame)
        topBar.backgroundColor = UIColor.black
        view.addSubview(topBar)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getMovies()
    }
    
    func setUpVM() {
        viewModel.moviesChanged = {[unowned self] (movies) -> Void in
            self.gettingMore = false
            self.movies.removeAll()
            self.movies.append(contentsOf: movies)
            if (self.cellSize == CGSize.zero) {
                Alamofire.request((self.movies.first?.imageUrl)!).responseImage { response in
                    if let image = response.result.value {
                        let size = image.size
                        var newSize = CGSize(width: self.cellWidth, height: 0)
                        newSize.height = newSize.width * size.height / size.width
                        self.cellSize = newSize
                    }
                    self.collectionView?.reloadData()
                }
            } else {
                self.collectionView?.reloadData()
            }
        }
        viewModel .onError = { (error) -> Void in
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count + (gettingMore ? 1 : 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = (gettingMore && indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1 ? LoadingMoreCollectionViewCell.identifier : MoviesCollectionViewCell.identifier)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
        if (cell.isKind(of: MoviesCollectionViewCell.self)) {
            let movieCell = cell as! MoviesCollectionViewCell
            let movie = movies[indexPath.row]
            movieCell.config(movie: movie)
        } else {
            let loadingCell = cell as! LoadingMoreCollectionViewCell
            loadingCell.loadingView.startAnimating()
        }
        return cell
    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if (gettingMore && indexPath.row == collectionView.numberOfItems(inSection: indexPath.section) - 1) {
            return CGSize(width: (self.collectionView?.bounds.width)!, height: 60)
        }
        if (cellSize == CGSize.zero) {
            let width = cellWidth
            let height = (self.collectionView?.bounds.height)! / 3
            cellSize = CGSize(width: width, height: height)
        }
        
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        gettingMore = viewModel.checkForMore(movieIndex: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedMovie = movies[indexPath.row]
        gotoDetail()
        
    }
    
    func gotoDetail() {
        performSegue(withIdentifier: "detail", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? MovieDetailViewController, let movie = selectedMovie {
            controller.movieId = movie.id!
        }
    }

    @IBAction func toggleMovies() {
        if (viewModel.lastType == .Popular) {
            viewModel.getTopMovies()
        } else {
            viewModel.getPopularMovies()
        }
        updateMoviesButton(viewModel.lastType)
        updateTitle(viewModel.lastType)
    }
    
    func getMovies() {
        if (viewModel.lastType == .TopRated) {
            viewModel.getTopMovies()
        } else {
            viewModel.getPopularMovies()
        }
    }
    
    func updateMoviesButton(_ type: MoviesType) {
        var image: UIImage!
        if (type == .TopRated) {
            image = UIImage(named: "popular")
        } else {
            image = UIImage(named: "top")
        }
        let lastItemColor = self.navigationItem.rightBarButtonItem?.tintColor
        let buttonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(MoviesListController.toggleMovies))
        buttonItem.tintColor = lastItemColor
        let items = [buttonItem]
        self.navigationItem.rightBarButtonItem = buttonItem
    }
    
    func updateTitle(_ type: MoviesType) {
        let locString = (type == .Popular ? "PopularMovies" : "TopRatedMovies")
        self.title = locString.localized()
    }
}

