const admin = require('firebase-admin');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// 1. Locate serviceAccountKey.json
let serviceAccountPath = path.resolve(process.cwd(), 'serviceAccountKey.json');
if (!fs.existsSync(serviceAccountPath)) {
  serviceAccountPath = path.resolve(__dirname, '..', 'serviceAccountKey.json');
}

if (!fs.existsSync(serviceAccountPath)) {
  console.error('\n❌ ERROR: serviceAccountKey.json was not found!');
  console.error('Please download your Service Account JSON key from Firebase Console:');
  console.error('Project Settings > Service Accounts > Generate New Private Key');
  console.error(`And place it at: ${path.resolve(process.cwd(), 'serviceAccountKey.json')}\n`);
  process.exit(1);
}

// 2. Initialize Firebase Admin SDK
const serviceAccount = require(serviceAccountPath);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

// 3. Cryptographically Secure 10-character Temporary Password Generator
function generateTempPassword() {
  const uppers = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  const lowers = 'abcdefghijkmnopqrstuvwxyz';
  const numbers = '23456789';
  const symbols = '!@#$%&*';
  const allChars = uppers + lowers + numbers + symbols;

  const getRandomChar = (str) => str[crypto.randomInt(0, str.length)];

  // Ensure at least one character from each required set
  const passwordArray = [
    getRandomChar(uppers),
    getRandomChar(lowers),
    getRandomChar(numbers),
    getRandomChar(symbols),
  ];

  // Fill remaining 6 positions randomly
  for (let i = 0; i < 6; i++) {
    passwordArray.push(getRandomChar(allChars));
  }

  // Shuffle array using Fisher-Yates
  for (let i = passwordArray.length - 1; i > 0; i--) {
    const j = crypto.randomInt(0, i + 1);
    [passwordArray[i], passwordArray[j]] = [passwordArray[j], passwordArray[i]];
  }

  return passwordArray.join('');
}

// 4. Data Definition
const collegesData = [
  { id: 'JECC', name: 'Jyothi Engineering College', code: 'JECC' },
  { id: 'MACE', name: 'Mar Athanasius College of Engineering, Kothamangalam', code: 'MACE' },
  { id: 'GECT', name: 'Government Engineering College, Thrissur', code: 'GECT' }
];

const studentsData = [
  // JECC
  { admissionNo: '23CS101', name: 'Sachin PK', email: 'sachin.pk@jecc.ac.in', collegeCode: 'JECC' },
  { admissionNo: '23CS102', name: 'Ananya Nair', email: 'ananya.nair@jecc.ac.in', collegeCode: 'JECC' },
  { admissionNo: '23CS103', name: 'Rohan Sharma', email: 'rohan.sharma@jecc.ac.in', collegeCode: 'JECC' },
  // MACE
  { admissionNo: '23EC201', name: 'Fathima R', email: 'fathima.r@mace.ac.in', collegeCode: 'MACE' },
  { admissionNo: '23EC202', name: 'Arjun V', email: 'arjun.v@mace.ac.in', collegeCode: 'MACE' },
  { admissionNo: '23EC203', name: 'Devika S', email: 'devika.s@mace.ac.in', collegeCode: 'MACE' },
  // GECT
  { admissionNo: '23ME301', name: 'Kevin Paul', email: 'kevin.paul@gect.ac.in', collegeCode: 'GECT' },
  { admissionNo: '23ME302', name: 'Meera Krishnan', email: 'meera.k@gect.ac.in', collegeCode: 'GECT' },
  { admissionNo: '23ME303', name: 'Siddharth Menon', email: 'siddharth.m@gect.ac.in', collegeCode: 'GECT' }
];

async function seedDatabase() {
  console.log('\n🚀 Starting Firebase Seed Script for Career Digital Twin...\n');

  // Step A: Seed Colleges Collection
  console.log('--- Seeding Colleges ---');
  for (const col of collegesData) {
    const colRef = db.collection('colleges').doc(col.id);
    await colRef.set({
      name: col.name,
      code: col.code
    }, { merge: true });
    console.log(`✅ College seeded: [${col.code}] ${col.name}`);
  }

  // Step B: Seed Students in Auth & Firestore
  console.log('\n--- Seeding Students ---');
  const csvRows = ['College,Admission No,Student Name,Synthetic Email,Real Email,Temporary Password'];
  const summaryList = [];

  for (const student of studentsData) {
    const syntheticEmail = `${student.admissionNo.toLowerCase()}@${student.collegeCode.toLowerCase()}.internal`;
    let userRecord;
    let tempPassword = '';
    let isNewUser = false;

    try {
      // Check if Firebase Auth user exists
      userRecord = await auth.getUserByEmail(syntheticEmail);
      console.log(`⚠️  Auth User already exists: ${syntheticEmail} (UID: ${userRecord.uid})`);
      tempPassword = '[EXISTS - UNCHANGED]';
    } catch (err) {
      if (err.code === 'auth/user-not-found') {
        // Generate password and create user
        tempPassword = generateTempPassword();
        userRecord = await auth.createUser({
          email: syntheticEmail,
          password: tempPassword,
          displayName: student.name
        });
        isNewUser = true;
        console.log(`✨ Created Auth User: ${syntheticEmail} (UID: ${userRecord.uid})`);
      } else {
        console.error(`❌ Error fetching Auth user ${syntheticEmail}:`, err);
        throw err;
      }
    }

    // Hash password (if new user generate hash, else placeholder)
    const passwordHash = isNewUser ? await bcrypt.hash(tempPassword, 10) : '[EXISTING_HASH]';

    // Seed/Update Firestore student document
    const studentDocRef = db.collection('students').doc(userRecord.uid);
    const existingDoc = await studentDocRef.get();

    const studentDocData = {
      collegeId: student.collegeCode,
      admissionNo: student.admissionNo,
      name: student.name,
      email: student.email,
      mustResetPassword: existingDoc.exists ? (existingDoc.data().mustResetPassword ?? true) : true,
    };

    if (isNewUser) {
      studentDocData.passwordHash = passwordHash;
      studentDocData.createdAt = admin.firestore.FieldValue.serverTimestamp();
    }

    await studentDocRef.set(studentDocData, { merge: true });
    console.log(`  └─ Firestore doc created/updated at students/${userRecord.uid}`);

    // Store for CSV & summary
    csvRows.push(`"${student.collegeCode}","${student.admissionNo}","${student.name}","${syntheticEmail}","${student.email}","${tempPassword}"`);
    summaryList.push({
      college: student.collegeCode,
      admissionNo: student.admissionNo,
      name: student.name,
      syntheticEmail,
      tempPassword
    });
  }

  // Step C: Save Credentials CSV
  const csvOutputPath = path.resolve(process.cwd(), 'credentials_out.csv');
  fs.writeFileSync(csvOutputPath, csvRows.join('\n'), 'utf-8');
  console.log(`\n📄 Generated Credentials CSV at: ${csvOutputPath}`);

  // Step D: Print Final Credentials Summary
  console.log('\n========================================================================================');
  console.log('                              STUDENT INITIAL CREDENTIALS                                ');
  console.log('========================================================================================');
  console.log(String('COLLEGE').padEnd(10) + String('ADMISSION NO').padEnd(15) + String('STUDENT NAME').padEnd(20) + String('TEMP PASSWORD').padEnd(20) + 'SYNTHETIC EMAIL');
  console.log('----------------------------------------------------------------------------------------');
  summaryList.forEach(s => {
    console.log(s.college.padEnd(10) + s.admissionNo.padEnd(15) + s.name.padEnd(20) + s.tempPassword.padEnd(20) + s.syntheticEmail);
  });
  console.log('========================================================================================\n');
  console.log('🎉 Seeding completed successfully!\n');

  process.exit(0);
}

seedDatabase().catch(error => {
  console.error('\n❌ Fatal error during database seeding:', error);
  process.exit(1);
});
