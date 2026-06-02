const admin = require('firebase-admin');
const serviceAccount = require('./google-services.json'); // Ensure this matches your downloaded key

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Helper to generate search tokens for robust text search
function generateSearchTokens(name) {
    const tokens = [];
    const cleanName = name.toLowerCase().replace(/[^a-z0-9 ]/g, '');
    const words = cleanName.split(' ');
    for (let word of words) {
        for (let i = 1; i <= word.length; i++) {
            tokens.push(word.substring(0, i));
        }
    }
    return [...new Set(tokens)];
}

// The Data Generator Matrix
// The script will mix and match these to create 50 unique, realistic products.
const categories = ['Apparel', 'Footwear', 'Accessories', 'Streetwear'];
const materials = ['Organic Cotton', 'Heavyweight Fleece', 'Premium Leather', 'Ripstop Nylon', 'Suede', 'Merino Wool'];
const styles = ['Minimalist', 'Oversized', 'Vintage', 'Technical', 'Classic', 'Utility'];
const colors = ['Warm White', 'Ink Black', 'Stone Gray', 'Signal Indigo', 'Pebble'];
const baseItems = {
    'Apparel': ['Hoodie', 'Overshirt', 'Tee', 'Cargo Pants'],
    'Footwear': ['Sneakers', 'Boots', 'Runners'],
    'Accessories': ['Backpack', 'Crossbody Bag', 'Beanie'],
    'Streetwear': ['Windbreaker', 'Graphic Crewneck', 'Track Pants']
};

async function seedDatabase() {
    const batch = db.batch();
    const collectionRef = db.collection('products');

    console.log('Generating 50 portfolio-ready products. Sit tight...');

    for (let i = 1; i <= 50; i++) {
        // Randomly select attributes
        const category = categories[Math.floor(Math.random() * categories.length)];
        const material = materials[Math.floor(Math.random() * materials.length)];
        const style = styles[Math.floor(Math.random() * styles.length)];
        const color = colors[Math.floor(Math.random() * colors.length)];

        const possibleItems = baseItems[category];
        const itemType = possibleItems[Math.floor(Math.random() * possibleItems.length)];

        // Construct realistic product data
        const name = `${style} ${material} ${itemType}`;
        const basePrice = Math.floor(Math.random() * (150 - 40 + 1)) + 40; // Prices between $40 and $150
        const isOnSale = Math.random() > 0.8; // 20% chance to be on sale
        const salePrice = isOnSale ? Math.floor(basePrice * 0.75) : null;

        const productData = {
            name: name,
            description: `A premium quality ${itemType.toLowerCase()} designed for modern daily utility. Crafted using responsibly sourced ${material.toLowerCase()} featuring an exceptional texture profile, finished in a versatile ${color.toLowerCase()}.`,
            price: basePrice,
            salePrice: salePrice,
            category: category,
            color: color,
            material: material,
            style: style,
            tags: [category.toLowerCase(), style.toLowerCase(), material.toLowerCase().replace(' ', '-')],
            searchTokens: generateSearchTokens(name),
            imageUrls: [
                `https://images.unsplash.com/photo-mock-placeholder-${i}-1.jpg`, // Client app will cache these gracefully
                `https://images.unsplash.com/photo-mock-placeholder-${i}-2.jpg`
            ],
            variants: [
                { size: 'S', inventory: Math.floor(Math.random() * 20) },
                { size: 'M', inventory: Math.floor(Math.random() * 30) },
                { size: 'L', inventory: Math.floor(Math.random() * 15) }
            ],
            inventory: Math.floor(Math.random() * 65) + 10,
            rating: parseFloat((Math.random() * (5.0 - 4.1) + 4.1).toFixed(1)), // High ratings look better in demos
            reviewCount: Math.floor(Math.random() * 300) + 24,
            createdAt: admin.firestore.FieldValue.serverTimestamp()
        };

        // Use a clean, predictable ID format
        const docRef = collectionRef.doc(`HAUL-${1000 + i}`);
        batch.set(docRef, productData);
    }

    // Commit all 50 writes at once
    await batch.commit();
    console.log('Success! Your Firestore is now fully populated with 50 generated products.');
    process.exit(0);
}

seedDatabase().catch((error) => {
    console.error('Error seeding database: ', error);
    process.exit(1);
});