-- Objective answers


-- 1. Checking for duplicate or null values in tables
SELECT 'users', COUNT(*) - COUNT(DISTINCT id) AS Duplicates, SUM(username IS NULL) AS NullValues FROM users
UNION ALL
SELECT 'photos', COUNT(*) - COUNT(DISTINCT id), SUM(image_url IS NULL) FROM photos
UNION ALL
SELECT 'comments', COUNT(*) - COUNT(DISTINCT id), SUM(comment_text IS NULL) FROM comments
UNION ALL
SELECT 'likes', COUNT(*) - COUNT(DISTINCT user_id, photo_id), 0 FROM likes
UNION ALL
SELECT 'follows', COUNT(*) - COUNT(DISTINCT follower_id, followee_id), 0 FROM follows
UNION ALL
SELECT 'photo_tags', COUNT(*) - COUNT(DISTINCT photo_id, tag_id), 0 FROM photo_tags
UNION ALL
SELECT 'tags', COUNT(*) - COUNT(DISTINCT id), SUM(id IS NULL) FROM tags;

-- 2. Distribution of user activity levels (posts, likes, comments)
SELECT u.id, u.username,
       COUNT(DISTINCT p.id) AS TotalPosts,
       COUNT(DISTINCT l.photo_id) AS TotalLikes,
       COUNT(DISTINCT c.id) AS TotalComments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
ORDER BY TotalLikes DESC, TotalComments DESC, TotalPosts DESC;

-- 3. Average number of tags per post
SELECT AVG(tag_count) AS AvgTagsPerPost FROM (
    SELECT photo_id, COUNT(tag_id) AS tag_count
    FROM photo_tags
    GROUP BY photo_id
) t;

-- 4. Top users with highest engagement (likes + comments)
SELECT u.id, u.username, COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) AS Engagement
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY u.id, u.username
ORDER BY Engagement DESC
LIMIT 10;

-- 5. User with highest followers and followings
SELECT 'Most Followed' AS Category, followee_id AS UserID, COUNT(follower_id) AS Count 
FROM follows 
GROUP BY followee_id ORDER BY Count DESC 
LIMIT 5;

SELECT 'Most Following', follower_id, COUNT(followee_id) 
FROM follows 
GROUP BY follower_id 
ORDER BY COUNT(followee_id) 
DESC LIMIT 5;

-- 6. Average engagement rate per post
SELECT u.id, u.username, 
       AVG((SELECT COUNT(*) FROM likes l WHERE l.photo_id = p.id) + (SELECT COUNT(*) FROM comments c 
       WHERE c.photo_id = p.id)) AS AvgEngagementPerPost
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.username;

-- 7. Users who never liked any post
SELECT u.id, u.username FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

-- 8. Leveraging user-generated content for personalized ad campaigns
-- Identify top trending hashtags to target popular interests
SELECT t.tag_name, COUNT(*) AS UsageCount FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name ORDER BY UsageCount DESC LIMIT 10;

-- 9. Correlation between user activity and content type
SELECT 
    p.image_url, 
    COUNT(DISTINCT l.user_id) AS TotalLikes, 
    COUNT(DISTINCT c.id) AS TotalComments,
    (COUNT(DISTINCT l.user_id) + COUNT(DISTINCT c.id)) AS TotalEngagement,
    (COUNT(DISTINCT l.user_id) * 1.0 / NULLIF(COUNT(DISTINCT c.id), 0)) AS LikeToCommentRatio
FROM photos p
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY p.id
ORDER BY TotalEngagement DESC;

-- 10. Total likes, comments, and photo tags for each user
SELECT u.id, u.username,
       COUNT(DISTINCT l.photo_id) AS TotalLikes,
       COUNT(DISTINCT c.id) AS TotalComments,
       COUNT(DISTINCT pt.photo_id) AS TotalTags
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
LEFT JOIN photo_tags pt ON p.id = pt.photo_id
GROUP BY u.id, u.username;

-- 11. Rank users based on total engagement (likes, comments, shares) over a month
SELECT u.id, u.username, COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) AS TotalEngagement,
RANK() OVER(ORDER BY COUNT(DISTINCT l.photo_id) + COUNT(DISTINCT c.id) DESC) AS engagement_rank
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
WHERE p.created_dat >= NOW() - INTERVAL 1 MONTH
GROUP BY u.id, u.username
ORDER BY TotalEngagement DESC;

-- 12. Hashtags with highest average likes
WITH HashtagLikes AS (
    SELECT t.tag_name, AVG(l_count.likes) AS AvgLikes
    FROM photo_tags pt
    JOIN tags t ON pt.tag_id = t.id
    JOIN (SELECT photo_id, COUNT(*) AS likes FROM likes GROUP BY photo_id) l_count
    ON pt.photo_id = l_count.photo_id
    GROUP BY t.tag_name
)
SELECT * FROM HashtagLikes ORDER BY AvgLikes DESC LIMIT 10;

-- 13. Users who followed someone after being followed
SELECT f1.follower_id, f1.followee_id
FROM follows f1
JOIN follows f2 ON f1.follower_id = f2.followee_id AND f1.followee_id = f2.follower_id;





