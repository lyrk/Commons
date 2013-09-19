//
//  GalleryMultiSelectGroupAssetsVC.m
//  Commons-iOS
//
//  Created by Monte Hurd on 6/16/13.

#import "GalleryMultiSelectCollectionVC.h"
#import "GalleryMultiSelectAlbumCell.h"
#import "GalleryMultiSelectAssetCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "MWI18N/MWI18N.h"
#import "CommonsApp.h"

#pragma mark - Defines

// See "setSpacing" method for other layout adjustments
#define GALLERY_NON_IPAD_IMAGE_BORDER_WIDTH 2.0f
#define GALLERY_IPAD_IMAGE_BORDER_WIDTH 2.0f

#define GALLERY_ALBUM_BORDER_COLOR [UIColor whiteColor]
#define GALLERY_SELECTED_ALBUM_BORDER_COLOR [UIColor redColor]
#define GALLERY_IMAGE_BORDER_COLOR [UIColor whiteColor]
#define GALLERY_SELECTED_IMAGE_BORDER_COLOR [UIColor redColor]

typedef enum {
    GALLERY_SHOW_ALL_ALBUMS = 0,
    GALLERY_SHOW_SINGLE_ALBUM = 1
} GalleryMode;

@interface GalleryMultiSelectCollectionVC (){
    UISwipeGestureRecognizer *swipeRecognizer_;
    NSMutableArray *collectionData_;
    UINavigationBar *navBar_;
    float imageMargin_;
    float imageScale_;
    float cellScale_;
    NSURL *selectedAlbumGroupURL_;
}

@property (nonatomic) GalleryMode galleryMode;

@end

#pragma mark - Setup

@implementation GalleryMultiSelectCollectionVC

-(void)setup
{
    selectedAlbumGroupURL_ = nil;
    collectionData_ = [[NSMutableArray alloc] init];
    self.galleryMode = GALLERY_SHOW_ALL_ALBUMS;

    float scale = [[UIScreen mainScreen] scale];
    imageScale_ = 1.0f / scale;
    cellScale_ = 1.0f / scale;

    imageMargin_ = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? GALLERY_IPAD_IMAGE_BORDER_WIDTH : GALLERY_NON_IPAD_IMAGE_BORDER_WIDTH;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

#pragma mark - Memory

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - View

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadCollectionDataForCoverImagesThen:^{
        [self refresh];
    }];
    
    // Refresh in case photos/albums changed since the app was suspended
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    [self.collectionView setAllowsMultipleSelection:YES];
    
    swipeRecognizer_ = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                 action:@selector(handleSwipeDown:)];
    swipeRecognizer_.direction = UISwipeGestureRecognizerDirectionDown;
	[self.view addGestureRecognizer:swipeRecognizer_];
    
    [self addNavBar];
}

-(void)setSpacing
{
    // For info on autolayout with collectionviews, see: http://stackoverflow.com/a/17598033/135557

    UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(60.0f, 15.0f, 60.0f, 15.0f);
        collectionViewLayout.minimumInteritemSpacing = 10.0f;
        // Adds more space for the album labels
        collectionViewLayout.minimumLineSpacing = (self.galleryMode == GALLERY_SHOW_ALL_ALBUMS) ? 70.0f : 10.0f;
    }else{
        collectionViewLayout.sectionInset = UIEdgeInsetsMake(80.0f, 40.0f, 80.0f, 40.0f);
        collectionViewLayout.minimumInteritemSpacing = 40.0f;
        // Adds more space for the album labels
        collectionViewLayout.minimumLineSpacing = (self.galleryMode == GALLERY_SHOW_ALL_ALBUMS) ? 90.0f : 55.0f;
    }
}

-(void)addNavBar
{
    navBar_ = [[UINavigationBar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)];
    navBar_.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    navBar_.barStyle = UIBarStyleBlackTranslucent;
    [super.view addSubview:navBar_];

    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:[MWMessage forKey:@"gallery-cancel-button"].text
                                                                    style:UIBarButtonItemStyleDone
                                                                   target:self action:@selector(dismiss)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:[MWMessage forKey:@"gallery-album-title"].text];
    item.rightBarButtonItem = rightButton;
    [navBar_ pushNavigationItem:item animated:NO];
}

-(void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(void)setNavBarBackButtonVisible:(BOOL)visible
{
    UINavigationItem *thisItem = navBar_.items[0];
    if (visible) {
        NSString *backArrowStr = [[CommonsApp singleton] getBackButtonString];
        thisItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:backArrowStr style:UIBarButtonItemStylePlain target:self action:@selector(returnToAlbums)];
        thisItem.hidesBackButton = NO;
    }else{
        thisItem.hidesBackButton = YES;
        thisItem.leftBarButtonItem = nil;
    }
}

-(void)setNavBarTitle:(NSString *)title
{
    UINavigationItem *thisItem = navBar_.items[0];
    thisItem.title = title;
}

-(void)appWillEnterForeground
{
    if (selectedAlbumGroupURL_ != nil) {
        [self loadCollectionDataForAssetGroupURL:selectedAlbumGroupURL_ then:^{
            [self setNavBarTitle:collectionData_[0][@"name"]];
            [self refresh];
        }];
    }else{
        self.galleryMode = GALLERY_SHOW_SINGLE_ALBUM;
        [self returnToAlbums];
    }
}

-(void)refresh
{
    [self setSpacing];
    [self.collectionView reloadData];
}

#pragma mark - Gestures

-(void)handleSwipeDown:(UIGestureRecognizer *)recognizer
{
    [self dismiss];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UIImage *image = [collectionData_[indexPath.section][@"assets"] objectAtIndex:indexPath.row][@"thumb"];
    
    return CGSizeMake((image.size.width * cellScale_), (image.size.height * cellScale_));
}

- (void)returnToAlbums{
        if (self.galleryMode == GALLERY_SHOW_SINGLE_ALBUM) {
            self.galleryMode = GALLERY_SHOW_ALL_ALBUMS;
            selectedAlbumGroupURL_ = nil;
            [self loadCollectionDataForCoverImagesThen:^{
                [self setNavBarTitle:[MWMessage forKey:@"gallery-album-title"].text];
                [self refresh];
            }];
            [self setNavBarBackButtonVisible:NO];
            [self.collectionView reloadData];
        }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return [collectionData_[section][@"assets"] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (self.galleryMode) {
        case GALLERY_SHOW_ALL_ALBUMS:{
            GalleryMultiSelectAlbumCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"GalleryAlbumCell" forIndexPath:indexPath];
            [self configureCellImageView:cell.imageView forIndexPath:indexPath];
            [self configureBackgroundForCell:cell havingImageView:cell.imageView];
            [self configureLabelForCell:cell forIndexPath:indexPath];
            return cell;
            break;
        }
        case GALLERY_SHOW_SINGLE_ALBUM:{
            GalleryMultiSelectAssetCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"GalleryAssetCell" forIndexPath:indexPath];
            [self configureCellImageView:cell.imageView forIndexPath:indexPath];
            [self configureBackgroundForCell:cell havingImageView:cell.imageView];
            return cell;
            break;
        }
        default:
            return nil;
    }
}

#pragma mark - Cells

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return [collectionData_ count];
}

-(void)addMarginConstraintsToImageView:(UIImageView *)thisImageView
{
    void (^constrainImageView)(NSString *) = ^(NSString *vfString){
        [thisImageView.superview addConstraints:[NSLayoutConstraint
                                                 constraintsWithVisualFormat: vfString
                                                 options:  0
                                                 metrics:  @{@"margin" : @(imageMargin_)}
                                                 views:    @{@"imageView" : thisImageView}
                                                 ]];
    };
    constrainImageView(@"H:|-margin-[imageView]-margin-|");
    constrainImageView(@"V:|-margin-[imageView]-margin-|");
}

-(void)configureCellImageView:(UIImageView *)thisImageView forIndexPath:(NSIndexPath*)indexPath
{
    // Set the image
    thisImageView.image = [collectionData_[indexPath.section][@"assets"] objectAtIndex:indexPath.row][@"thumb"];

    // Add margin constraints between image view and its cell
    [self addMarginConstraintsToImageView:thisImageView];
}

-(void)configureBackgroundForCell:(UICollectionViewCell *)cell havingImageView:(UIImageView *) imageView
{
    // Set the selection color
    if (self.galleryMode == GALLERY_SHOW_ALL_ALBUMS) {
        cell.backgroundView.backgroundColor = GALLERY_ALBUM_BORDER_COLOR;
        cell.selectedBackgroundView.backgroundColor = GALLERY_SELECTED_ALBUM_BORDER_COLOR;
    }else{
        cell.backgroundView.backgroundColor = GALLERY_IMAGE_BORDER_COLOR;
        cell.selectedBackgroundView.backgroundColor = GALLERY_SELECTED_IMAGE_BORDER_COLOR;
    }
}

-(void)configureLabelForCell:(GalleryMultiSelectAlbumCell *)cell forIndexPath:(NSIndexPath*)indexPath
{
    // Set album label text
    // Display the album name beneath the image
    cell.label.text = [collectionData_[indexPath.section][@"assets"] objectAtIndex:indexPath.row][@"name"];
    
    // Snug the album label up to the bottom of the image
    CGRect f = cell.label.frame;
    f.origin.y = cell.imageView.frame.origin.y + cell.imageView.frame.size.height + 10.0f;
    cell.label.frame = f;
}

#pragma mark UICollectionViewDelegate (Selection)

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // An album cover photo was selected
    if (self.galleryMode == GALLERY_SHOW_ALL_ALBUMS) {
        self.galleryMode = GALLERY_SHOW_SINGLE_ALBUM;
        selectedAlbumGroupURL_ = [collectionData_[0][@"assets"] objectAtIndex:indexPath.row][@"url"];
        [self loadCollectionDataForAssetGroupURL:selectedAlbumGroupURL_ then:^{
            [self setNavBarTitle:collectionData_[0][@"name"]];
            [self refresh];
        }];
        [self setNavBarBackButtonVisible:YES];
    }else{
		// A photo was selected
		NSLog(@"single selection made!");

        // The assetRepresentation contains the image and its metadata
        ALAssetRepresentation *assetRepresentation = [collectionData_[indexPath.section][@"assets"] objectAtIndex:indexPath.row][@"defaultRepresentation"];
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        // When using the built-in image picker, the callback method "imagePickerController:didFinishPickingMediaWithInfo:"
        // is invoked when the user selects a photo. It populates the info dictionary with certain keys and values. Here the
        // selection for the image chosen with *this* picker is placed in a dictionary with the same keys that the built-in
        // picker would use
        info[UIImagePickerControllerOriginalImage] = [UIImage imageWithCGImage:[assetRepresentation fullResolutionImage]];
        info[UIImagePickerControllerMediaMetadata] = [assetRepresentation metadata];
        // Get the url to the asset as well
        info[UIImagePickerControllerReferenceURL] = [collectionData_[indexPath.section][@"assets"] objectAtIndex:indexPath.row][@"assetURL"];
        // Present the dictionary of data for the chosen image to the "didFinishPickingMediaWithInfo" callback
        // (mimics the built-in photo selector's "imagePickerController:didFinishPickingMediaWithInfo:" method)
        self.didFinishPickingMediaWithInfo(info);
	}
}

#pragma mark Datasource for album cover images

// Loads collectionData_ for showing a each album's first image
-(void)loadCollectionDataForCoverImagesThen:(void (^)(void))block;
{
    [collectionData_ removeAllObjects];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [collectionData_ addObject:dict];
    collectionData_[0][@"assets"] = [[NSMutableArray alloc] init];
    
    // Group enumerator Block
    void (^groupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group == nil){
            // The group is nil when the enumeration is finished!
            block();
            return;
        }
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop){
            if (index != 0){
                *stop = YES;
                return;
            }
            NSMutableDictionary *assetDict = [[NSMutableDictionary alloc] init];
            UIImage *thumbImage = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                ?
                [UIImage imageWithCGImage:[asset aspectRatioThumbnail]]
                :
                [UIImage imageWithCGImage:[asset thumbnail]]
            ;
            assetDict[@"url"] = [group valueForProperty:ALAssetsGroupPropertyURL];
            assetDict[@"name"] = [group valueForProperty:ALAssetsGroupPropertyName];
            assetDict[@"thumb"] = thumbImage;
            [collectionData_[0][@"assets"] addObject:assetDict];
        }];
    };
    // Group enumerator fail block
    void (^groupFail)(NSError *) = ^(NSError *error) {[self showError:error];};
    
    // Enumerate Albums
    [[GalleryMultiSelectCollectionVC defaultAssetsLibrary] enumerateGroupsWithTypes: (ALAssetsGroupSavedPhotos | ALAssetsGroupAlbum)
                           usingBlock: groupEnumerator failureBlock:groupFail];
}

#pragma mark Datasource for images within an album

// Loads collectionData_ for showing a single album's images
-(void)loadCollectionDataForAssetGroupURL:(NSURL *)groupURL then:(void (^)(void))block;
{
    [collectionData_ removeAllObjects];

    // Group enumerator Block
    void (^groupResult)(ALAssetsGroup *) = ^(ALAssetsGroup *group) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict[@"name"] = [group valueForProperty:ALAssetsGroupPropertyName];
        dict[@"url"] = [group valueForProperty:ALAssetsGroupPropertyURL];
        dict[@"assets"] = [[NSMutableArray alloc] init];
        
        [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop){
            if (asset == nil){
                // The asset is nil when the enumeration is finished!
                [collectionData_ addObject:dict];
                block();
                return;
            }
            NSMutableDictionary *assetDict = [[NSMutableDictionary alloc] init];
            UIImage *thumbImage = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                ?
                [UIImage imageWithCGImage:[asset aspectRatioThumbnail]]
                :
                [UIImage imageWithCGImage:[asset thumbnail]]
            ;
            assetDict[@"thumb"] = thumbImage;
            assetDict[@"assetURL"] = [asset valueForProperty:ALAssetPropertyAssetURL];
            assetDict[@"defaultRepresentation"] = [asset defaultRepresentation];

            [dict[@"assets"] addObject:assetDict];
        }];
    };
    
    // Group retrieval fail block
    void (^groupFail)(NSError *) = ^(NSError *error) {[self showError:error];};

    [[GalleryMultiSelectCollectionVC defaultAssetsLibrary] groupForURL:groupURL resultBlock:groupResult failureBlock:groupFail];
}

#pragma mark Error

-(void)showError:(NSError *)error{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"%@", [error description]] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    // From: http://www.daveoncode.com/2011/10/15/solve-xcode-error-invalid-attempt-to-access-alassetprivate-past-the-lifetime-of-its-owning-alassetslibrary/
    
    static dispatch_once_t once = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&once, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}


@end
