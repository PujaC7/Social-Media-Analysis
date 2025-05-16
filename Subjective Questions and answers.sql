-- Subjective answers


-- 1. Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
WITH user_activity AS (SELECT u.id AS user_id,u.username,
        IFNULL(photo_counts.total_photos, 0) AS total_photos,
        IFNULL(comment_counts.total_comments, 0) AS total_comments,
        IFNULL(like_counts.total_likes_given, 0) AS total_likes_given,
        IFNULL(follower_counts.total_followers, 0) AS total_followers,
        IFNULL(following_counts.total_following, 0) AS total_following,
        (IFNULL(photo_counts.total_photos, 0) +
            IFNULL(comment_counts.total_comments, 0) +
            IFNULL(like_counts.total_likes_given, 0)  +
            IFNULL(follower_counts.total_followers, 0)  +
            IFNULL(following_counts.total_following, 0) ) AS engagement_score
    FROM users u
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_photos FROM photos GROUP BY user_id) photo_counts ON u.id = photo_counts.user_id
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id) comment_counts ON u.id = comment_counts.user_id
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_likes_given FROM likes GROUP BY user_id) like_counts ON u.id = like_counts.user_id
    LEFT JOIN(SELECT followee_id AS user_id, COUNT(*) AS total_followers FROM follows GROUP BY followee_id) follower_counts ON u.id = follower_counts.user_id
    LEFT JOIN(SELECT follower_id AS user_id, COUNT(*) AS total_following FROM follows GROUP BY follower_id) following_counts ON u.id = following_counts.user_id),
ranked_users AS (SELECT user_id,username,engagement_score,RANK() OVER (ORDER BY engagement_score DESC) AS user_rank
    FROM user_activity)
SELECT user_id,username,engagement_score,user_rank
FROM ranked_users
WHERE user_rank = 1;


-- 2. For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
WITH user_activity AS (SELECT u.id AS user_id,u.username,
        IFNULL(photo_counts.total_photos, 0) AS total_photos,
        IFNULL(comment_counts.total_comments, 0) AS total_comments,
        IFNULL(like_counts.total_likes_given, 0) AS total_likes_given,
        IFNULL(follower_counts.total_followers, 0) AS total_followers,
        IFNULL(following_counts.total_following, 0) AS total_following,
        (IFNULL(photo_counts.total_photos, 0) +
            IFNULL(comment_counts.total_comments, 0) +
            IFNULL(like_counts.total_likes_given, 0)  +
            IFNULL(follower_counts.total_followers, 0)  +
            IFNULL(following_counts.total_following, 0) ) AS engagement_score
    FROM users u
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_photos FROM photos GROUP BY user_id) photo_counts ON u.id = photo_counts.user_id
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_comments FROM comments GROUP BY user_id) comment_counts ON u.id = comment_counts.user_id
    LEFT JOIN(SELECT user_id, COUNT(*) AS total_likes_given FROM likes GROUP BY user_id) like_counts ON u.id = like_counts.user_id
    LEFT JOIN(SELECT followee_id AS user_id, COUNT(*) AS total_followers FROM follows GROUP BY followee_id) follower_counts ON u.id = follower_counts.user_id
    LEFT JOIN(SELECT follower_id AS user_id, COUNT(*) AS total_following FROM follows GROUP BY follower_id) following_counts ON u.id = following_counts.user_id),
ranked_users AS (SELECT user_id,username,engagement_score,RANK() OVER (ORDER BY engagement_score ASC) AS user_rank
    FROM user_activity)
SELECT user_id,username,engagement_score,user_rank
FROM ranked_users
WHERE user_rank = '1';


-- 3. Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns? 
SELECT
    t.tag_name,
    COUNT(pt.photo_id) AS total_posts,
    COALESCE(SUM(likes.total_likes), 0) AS total_likes,
    COALESCE(SUM(comments.total_comments), 0) AS total_comments,
    (COALESCE(SUM(likes.total_likes), 0) + COALESCE(SUM(comments.total_comments), 0)) / COUNT(pt.photo_id) AS average_engagement
FROM
    tags t
JOIN
    photo_tags pt ON t.id = pt.tag_id
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) likes ON pt.photo_id = likes.photo_id
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) comments ON pt.photo_id = comments.photo_id
GROUP BY
    t.tag_name
ORDER BY
    average_engagement DESC
LIMIT 10;


-- 4. Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
SELECT
    DATE_FORMAT(p.created_dat, '%H') AS hour_of_day,
    DAYNAME(p.created_dat) AS day_of_week,
    COUNT(p.id) AS total_posts,
    COALESCE(SUM(likes.total_likes), 0) AS total_likes,
    COALESCE(SUM(comments.total_comments), 0) AS total_comments,
    (COALESCE(SUM(likes.total_likes), 0) + COALESCE(SUM(comments.total_comments), 0)) / COUNT(p.id) AS average_engagement
FROM
    photos p
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) likes ON p.id = likes.photo_id
LEFT JOIN
    (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) comments ON p.id = comments.photo_id
GROUP BY
    hour_of_day, day_of_week
ORDER BY
    average_engagement DESC
LIMIT 0, 1000;


-- 5. Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(f.follower_id) AS follower_count,
    COALESCE(SUM(likes.total_likes), 0) AS total_likes,
    COALESCE(SUM(comments.total_comments), 0) AS total_comments,
    COALESCE(SUM(likes.total_likes), 0) + COALESCE(SUM(comments.total_comments), 0) AS total_engagement,
    CASE WHEN COUNT(f.follower_id) > 0 THEN 
        (COALESCE(SUM(likes.total_likes), 0) + COALESCE(SUM(comments.total_comments), 0)) / COUNT(f.follower_id)
    ELSE 0 END AS engagement_rate
FROM 
    users u
LEFT JOIN 
    follows f ON u.id = f.followee_id
LEFT JOIN 
    (SELECT photo_id, COUNT(*) AS total_likes FROM likes GROUP BY photo_id) likes
    ON u.id = (SELECT user_id FROM photos WHERE id = likes.photo_id)
LEFT JOIN 
    (SELECT photo_id, COUNT(*) AS total_comments FROM comments GROUP BY photo_id) comments 
    ON u.id = (SELECT user_id FROM photos WHERE id = comments.photo_id)
GROUP BY 
    u.id, u.username
ORDER BY 
    engagement_rate DESC, follower_count DESC
    LIMIT 10;
  

-- 6.Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(SUM(likes_count), 0) AS total_likes,
    COALESCE(SUM(comments_count), 0) AS total_comments,
    COALESCE(COUNT(DISTINCT p.id), 0) AS total_photos,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 0 
        ELSE (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) 
    END AS engagement_rate,
    CASE 
        WHEN COALESCE(COUNT(DISTINCT p.id), 0) = 0 THEN 'Low'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) > 150 THEN 'High'
        WHEN (COALESCE(SUM(likes_count), 0) + COALESCE(SUM(comments_count), 0)) / COALESCE(COUNT(DISTINCT p.id), 1) BETWEEN 100 AND 150 
        THEN 'Medium'
        ELSE 'Low'
    END AS engagement_level
FROM users u
LEFT JOIN (SELECT user_id, COUNT(*) AS likes_count FROM likes GROUP BY user_id) l ON u.id = l.user_id
LEFT JOIN (SELECT user_id, COUNT(*) AS comments_count FROM comments GROUP BY user_id) c ON u.id = c.user_id
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY u.id, u.username
ORDER BY engagement_rate DESC;


