// home/repost_card.dart

import 'package:flutter/material.dart';
import 'package:cook/models/feed/repost_item.dart';
import 'package:cook/models/feed/user_info.dart';
import 'package:cook/home/video_post.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cook/services/loginservice.dart';
import 'package:cook/home/comment.dart';
import 'package:cook/home/report_dialog.dart';
import 'package:cook/maintenance/expiredtoken.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cook/models/LikeRequest_model.dart';
import 'package:cook/models/bookmarkrequest_model.dart';
import 'package:cook/services/post_service.dart';
import 'package:cook/profile/otheruserprofilepage.dart';
import 'package:cook/profile/profile_page.dart';
import 'full_screen_image_page.dart';

class RepostCard extends StatefulWidget {
  final RepostItem feedItem;

  const RepostCard({Key? key, required this.feedItem}) : super(key: key);

  @override
  _RepostCardState createState() => _RepostCardState();
}

class _RepostCardState extends State<RepostCard> with TickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late bool _isBookmarked;
  late AnimationController _bookmarkAnimationController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.feedItem.isLiked;
    _likeCount = widget.feedItem.post.likeCount;
    _isBookmarked = widget.feedItem.isBookmarked;

    _bookmarkAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.8,
      upperBound: 1.2,
    );

    _fetchCurrentUserId();
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    _currentUserId = await LoginService().getUserId();
  }

    void _viewImageFullscreen(List<String> mediaUrls, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImagePage(
          mediaUrls: mediaUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Future<void> _handleLike() async {
    final userId = await LoginService().getUserId();

    if (userId == null) {
      return;
    }

    final postId = widget.feedItem.post.postId;

    try {
      if (_isLiked) {
        // Unlike the post
        await PostService.unlikePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // Like the post
        await PostService.likePost(
          LikeRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        print('Failed to like/unlike post: $e');
      }
    }
  }

  Future<void> _handleBookmark() async {
    final userId = await LoginService().getUserId();

    if (userId == null) {
      return;
    }

    final postId = widget.feedItem.post.postId;

    await _bookmarkAnimationController.forward();

    try {
      if (_isBookmarked) {
        // Unbookmark the post
        await PostService.unbookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isBookmarked = false;
        });
      } else {
        // Bookmark the post
        await PostService.bookmarkPost(
          BookmarkRequest(userId: userId, postId: postId),
        );
        setState(() {
          _isBookmarked = true;
        });
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) {
        if (context.mounted) {
          handleSessionExpired(context);
        }
      } else {
        print('Failed to bookmark/unbookmark post: $e');
      }
    }

    await _bookmarkAnimationController.reverse();
  }

  void _viewComments(int postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CommentPage(postId: postId),
      ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // Rounded corners
          ),
          backgroundColor: Colors.white, // Background color for the dialog
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Padding for the content
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Choose an Action",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Color(0xFFF45F67), // Primary color for the title
                  ),
                ),
                const SizedBox(height: 16.0),
                Divider(color: Colors.grey[300], thickness: 1.0), // Divider for separation
                const SizedBox(height: 12.0),
                if (_currentUserId == widget.feedItem.user.userId) ...[
                  ListTile(
                    leading: Icon(Icons.delete, color: Colors.red[400]),
                    title: Text(
                      'Delete Repost',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement delete functionality here
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(Icons.report, color: Colors.red[400]),
                    title: Text(
                      'Report Post',
                      style: TextStyle(color: Colors.red[400]),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      showReportDialog(
                        context: context,
                        reportedUser: widget.feedItem.post.author?.userId ?? 0,
                        contentId: widget.feedItem.post.postId,
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  final sharer = widget.feedItem.user;
  final post = widget.feedItem.post;
  final author = post.author;
  final screenWidth = MediaQuery.of(context).size.width;

  return Container(
    width: screenWidth,
    margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 4.0),
    padding: const EdgeInsets.all(12.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(color: Colors.grey[300]!, width: 1), // Added grey[300] border
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sharer Information Row with Options Icon
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                int? currentUserId = await LoginService().getUserId();
                if (currentUserId == sharer.userId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtherUserProfilePage(
                        otherUserId: sharer.userId,
                      ),
                    ),
                  );
                }
              },
              child: CircleAvatar(
                backgroundImage: sharer.profilePictureUrl.isNotEmpty
                    ? CachedNetworkImageProvider(sharer.profilePictureUrl)
                    : AssetImage('assets/images/default.png') as ImageProvider,
                radius: 18,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  int? currentUserId = await LoginService().getUserId();
                  if (currentUserId == sharer.userId) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfilePage()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtherUserProfilePage(
                          otherUserId: sharer.userId,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sharer.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      timeago.format(widget.feedItem.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: Color(0xFFF45F67)),
              onPressed: () {
                _showPostOptions(context);
              },
            ),
          ],
        ),
        // Repost Content (Comment)
        if (widget.feedItem.content.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          Text(
            widget.feedItem.content,
            style: const TextStyle(fontSize: 16.0, color: Colors.black87),
          ),
        ],
        // Original Post Content
        const SizedBox(height: 8.0),
        _buildOriginalPost(context),
      ],
    ),
  );
}

  Widget _buildOriginalPost(BuildContext context) {
    final post = widget.feedItem.post;
    final author = post.author;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original Author Information Row
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (author != null) {
                    int? currentUserId = await LoginService().getUserId();
                    if (currentUserId == author.userId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfilePage(
                            otherUserId: author.userId,
                          ),
                        ),
                      );
                    }
                  }
                },
                child: CircleAvatar(
                  backgroundImage: author != null && author.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(author.profilePictureUrl)
                      : AssetImage('assets/images/default.png') as ImageProvider,
                  radius: 18,
                ),
              ),
              const SizedBox(width: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    author?.fullName ?? 'Unknown User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  Text(
                    timeago.format(post.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12.0),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (post.content.isNotEmpty)
            Text(
              post.content,
              style: const TextStyle(fontSize: 16.0),
            ),
          const SizedBox(height: 8.0),
          _buildMediaContent(screenWidth),
          const SizedBox(height: 8.0),
          _buildPostActions(),
        ],
      ),
    );
  }

  Widget _buildMediaContent(double screenWidth) {
  final post = widget.feedItem.post;

  if (post.media.isEmpty) {
    return const SizedBox.shrink();
  }

  double mediaHeight = screenWidth * 0.75;
  double maxHeight = 300.0;
  if (mediaHeight > maxHeight) {
    mediaHeight = maxHeight;
  }

  return SizedBox(
    height: mediaHeight,
    width: screenWidth,
    child: PageView.builder(
      itemCount: post.media.length,
      itemBuilder: (context, index) {
        final media = post.media[index];

        if (media.mediaType == 'photo') {
          return GestureDetector(
            onTap: () {
              // Call _viewImageFullscreen when the image is tapped
              _viewImageFullscreen(
                post.media.map((m) => m.mediaUrl).toList(), // Pass all media URLs
                index, // Pass the current index for the initial image
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: CachedNetworkImage(
                imageUrl: media.mediaUrl,
                fit: BoxFit.cover,
                width: screenWidth,
                height: mediaHeight,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          );
        } else if (media.mediaType == 'video') {
          return GestureDetector(
            onTap: () {
              // For videos, you might want to implement full-screen video view if needed
              _viewImageFullscreen(
                post.media.map((m) => m.mediaUrl).toList(), // Pass all media URLs
                index, // Pass the current index for the initial media
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: VideoPost(mediaUrl: media.mediaUrl),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    ),
  );
}


  Widget _buildPostActions() {
    final post = widget.feedItem.post;

    return Row(
      children: [
        // Like Button
        IconButton(
          icon: Icon(
            _isLiked ? Icons.favorite : Icons.favorite_border,
            color: Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: _handleLike,
        ),
        Text(
          '$_likeCount',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        // Comment Button
        IconButton(
          icon: Icon(
            Icons.comment,
            color: Color(0xFFF45F67),
            size: 28,
          ),
          onPressed: () => _viewComments(post.postId),
        ),
        Text(
          '${post.commentCount}',
          style: TextStyle(color: Color(0xFFF45F67)),
        ),
        const SizedBox(width: 16.0),

        const Spacer(),

        // Bookmark Button
        ScaleTransition(
          scale: _bookmarkAnimationController,
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Color(0xFFF45F67),
              size: 28,
            ),
            onPressed: _handleBookmark,
          ),
        ),
      ],
    );
  }
}