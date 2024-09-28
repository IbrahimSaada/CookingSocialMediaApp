import 'package:flutter/material.dart';
import 'package:cook/menu/editprofilepage.dart';
import 'dart:io';
import 'package:cook/services/LoginService.dart';
import 'package:cook/services/Userprofile_service.dart';
import 'package:cook/models/userprofileresponse_model.dart';
import 'package:cook/services/Post_service.dart';
import 'package:cook/models/post_model.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isPostsSelected = true;
  bool isLoading = false;
  String username = '';
  String bio = '';
  File? profileImage;
  int? userId;
  double rating = 0.0;
  int postNb = 0;
  int followersNb = 0;
  int followingNb = 0;
  UserProfile? userProfile;
  List<Post> userPosts = [];
  List<Post> bookmarkedPosts = [];

  final LoginService _loginService = LoginService();
  final UserProfileService _userProfileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      isLoading = true;
    });

    final isLoggedIn = await _loginService.isLoggedIn();
    if (isLoggedIn) {
      final userId = await _loginService.getUserId();
      if (userId != null) {
        userProfile = await _userProfileService.fetchUserProfile(userId);
        if (userProfile != null) {
          setState(() {
            this.userId = userId;
            username = userProfile!.fullName;
            bio = userProfile!.bio;
            rating = userProfile!.rating;
            postNb = userProfile!.postNb;
            followersNb = userProfile!.followersNb;
            followingNb = userProfile!.followingNb;
          });
        }
        // Fetch posts and bookmarks
        await _fetchUserPosts();
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchUserPosts() async {
    try {
      if (userId != null) {
        List<Post> posts = await PostService.fetchPosts(userId: userId!);
        setState(() {
          userPosts = posts.where((post) => !post.isBookmarked).toList();
          bookmarkedPosts = posts.where((post) => post.isBookmarked).toList();
        });
      }
    } catch (e) {
      print("Error fetching posts: $e");
    }
  }

void _openEditProfilePage() async {
  final result = await Navigator.push(
    context,
    PageRouteBuilder(
      opaque: false,  // Make the page route transparent
      pageBuilder: (BuildContext context, _, __) {
        return EditProfilePage(
          currentUsername: username,
          currentBio: bio,
          currentImage: profileImage,
        );
      },
    ),
  );

  if (result != null) {
    setState(() {
      username = result['username'];
      bio = result['bio'];
      profileImage = result['imageFile'];
    });
  }
}

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: screenHeight * 0.28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.18,
            left: 0,
            right: 0,
            child: Container(
              height: screenHeight * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 50,
            right: 10,
            child: IconButton(
              icon: Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // Add settings functionality
              },
            ),
          ),
Padding(
  padding: EdgeInsets.only(top: screenHeight * 0.09),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: <Widget>[
      CircleAvatar(
        radius: screenWidth * 0.15, // Responsive size for the avatar
        backgroundImage: userProfile != null
            ? NetworkImage(userProfile!.profilePic)
            : AssetImage('assets/images/default.png'),
      ),
      SizedBox(height: screenHeight * 0.02), // Responsive spacing
      Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _openEditProfilePage,
                child: Icon(
                  Icons.edit, 
                  color: Colors.orangeAccent, 
                  size: screenWidth * 0.07,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                username,
                style: TextStyle(
                  fontSize: screenWidth * 0.05, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis, // Prevent text overflow
                maxLines: 1, // Ensure the username stays on one line
              ),
              SizedBox(width: screenWidth * 0.02),
              Icon(
                Icons.qr_code,
                size: screenWidth * 0.07,
                color: Colors.grey,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01), // Spacing between username and bio
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1), // Add padding to prevent overflow
            child: Text(
              bio.isNotEmpty ? bio : 'No bio available',
              textAlign: TextAlign.center, // Center align the bio
              style: TextStyle(
                fontSize: screenWidth * 0.04, // Responsive font size for bio
                color: Colors.grey,
              ),
              overflow: TextOverflow.ellipsis, // Handle long bio gracefully
              maxLines: 3, // Limit the bio to 3 lines
            ),
          ),
        ],
      ),
      SizedBox(height: screenHeight * 0.02), // Spacing before stats
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatItem(postNb.toString(), 'Posts', screenWidth),
          SizedBox(width: screenWidth * 0.08),
          _buildStatItem(followersNb.toString(), 'Followers', screenWidth),
          SizedBox(width: screenWidth * 0.08),
          _buildStatItem(followingNb.toString(), 'Following', screenWidth),
        ],
      ),
      SizedBox(height: screenHeight * 0.02), // Spacing after stats
      Divider(
        color: Colors.orange,
        thickness: 2,
      ),
      SizedBox(height: screenHeight * 0.01), // Add a little spacing before posts section
      Expanded(
        // Make sure the posts section is properly expanded and visible
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isPostsSelected = true;
                    });
                  },
                  child: Icon(
                    Icons.grid_on,
                    color: isPostsSelected ? Colors.orange : Colors.grey,
                    size: screenWidth * 0.07,
                  ),
                ),
                SizedBox(width: screenWidth * 0.2),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isPostsSelected = false;
                    });
                  },
                  child: Icon(
                    Icons.bookmark,
                    color: !isPostsSelected ? Colors.orange : Colors.grey,
                    size: screenWidth * 0.07,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading indicator while loading posts
                  : isPostsSelected
                      ? _buildPosts(screenWidth) // Show user posts
                      : _buildSavedPosts(screenWidth), // Show bookmarked posts
            ),
          ],
        ),
      ),
    ],
  ),
),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, double screenWidth) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildPosts(double screenWidth) {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,  // 3 posts per row
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
        childAspectRatio: 1, // Ensures square grid items
      ),
      itemCount: userPosts.length,
      itemBuilder: (context, index) {
        final post = userPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(post);
          },
          child: _buildPostThumbnail(post),
        );
      },
    );
  }

  Widget _buildSavedPosts(double screenWidth) {
    return GridView.builder(
      padding: EdgeInsets.all(10.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,  // 3 posts per row
        crossAxisSpacing: screenWidth * 0.02,
        mainAxisSpacing: screenWidth * 0.02,
        childAspectRatio: 1, // Ensures square grid items
      ),
      itemCount: bookmarkedPosts.length,
      itemBuilder: (context, index) {
        final post = bookmarkedPosts[index];
        return GestureDetector(
          onTap: () {
            _openFullPost(post);
          },
          child: _buildPostThumbnail(post),
        );
      },
    );
  }

  Widget _buildPostThumbnail(Post post) {
    if (post.media.isNotEmpty) {
      if (post.media[0].mediaType == 'video') {
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
              child: Image.network(
                post.media[0].mediaUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildErrorPlaceholder();
                },
              ),
            ),
            // Centered video play icon
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
          child: Image.network(
            post.media[0].mediaUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildErrorPlaceholder();
            },
          ),
        );
      }
    } else {
      // If no media, it's a caption-only post, display a 'TT' icon
      return Container(
        color: Colors.orange,
        child: Center(
          child: Icon(
            Icons.text_fields, // 'TT' icon representing a caption
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.error,
          color: Colors.red,
          size: 24,
        ),
      ),
    );
  }

  void _openFullPost(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullPostPage(post: post),
      ),
    );
  }
}

// Full Post Page to display the post details
class FullPostPage extends StatelessWidget {
  final Post post;

  const FullPostPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.media.isNotEmpty)
              if (post.media[0].mediaType == 'video')
                Container(
                  height: 200,
                  color: Colors.black,
                  child: Center(child: Icon(Icons.videocam, color: Colors.white, size: 100)),
                )
              else
                Image.network(post.media[0].mediaUrl),
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  post.caption,
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
