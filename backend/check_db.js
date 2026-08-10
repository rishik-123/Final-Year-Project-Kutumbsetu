const mongoose = require('mongoose');
require('dotenv').config();

mongoose.connect(process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/kutumbsetu')
  .then(async () => {
    console.log('Connected to MongoDB.');
    
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log('Collections:', collections.map(c => c.name));
    
    // Check Reels
    const reels = await mongoose.connection.db.collection('reels').find({}).toArray();
    console.log(`Found ${reels.length} reels in database:`);
    reels.forEach((r, idx) => {
      console.log(`[Reel ${idx+1}] ID: ${r._id}, Author: ${r.authorName}, VideoUrl: ${r.videoUrl}, Likes: ${r.likes ? r.likes.length : 0}, Comments: ${r.comments ? r.comments.length : 0}`);
    });

    // Check Posts
    const posts = await mongoose.connection.db.collection('posts').find({}).toArray();
    console.log(`Found ${posts.length} posts in database:`);
    posts.forEach((p, idx) => {
      console.log(`[Post ${idx+1}] ID: ${p._id}, Author: ${p.authorName}, MediaUrl: ${p.mediaUrl}`);
    });

    process.exit(0);
  })
  .catch(err => {
    console.error('Database connection error:', err);
    process.exit(1);
  });
