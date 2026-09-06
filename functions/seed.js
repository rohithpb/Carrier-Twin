/**
 * Firestore Database Seeder Script
 * Run this script to populate your Firebase Firestore database with:
 * 1. Skill trees for the 4 Career Paths: Full Stack, Web, Cloud, ML
 * 2. Pre-computed dummy mentor profiles for Cosine Similarity matching
 * 
 * Usage:
 * node seed.js
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

const careerPaths = [
  {
    id: "fs_path",
    title: "Full Stack Development",
    iconName: "layers",
    description: "Extracted from Stack Overflow 2023 & Job Postings 2025 datasets.",
    skills: [
      {
        id: "fs1",
        title: "Frontend Frameworks (React / Next.js)",
        category: "Frontend",
        description: "UI components, Server Components, client state management.",
        difficulty: "Intermediate",
        estimatedHours: 30,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "fs2",
        title: "Node.js Backend & REST APIs",
        category: "Backend",
        description: "Express server architecture, middleware, JWT auth.",
        difficulty: "Intermediate",
        estimatedHours: 25,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "fs3",
        title: "PostgreSQL & Relational DB Design",
        category: "Database",
        description: "Schema modeling, migrations, indexing, transactions.",
        difficulty: "Intermediate",
        estimatedHours: 20,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "fs4",
        title: "Git, GitHub Actions & CI/CD Pipelines",
        category: "DevOps",
        description: "Branch strategies, pull request workflows, automated testing.",
        difficulty: "Beginner",
        estimatedHours: 15,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "fs5",
        title: "System Design & Scalable Architecture",
        category: "Architecture",
        description: "Caching (Redis), load balancers, rate limiting, microservices.",
        difficulty: "Advanced",
        estimatedHours: 35,
        isCompleted: false,
        prerequisites: []
      }
    ]
  },
  {
    id: "web_path",
    title: "Web Development",
    iconName: "web",
    description: "Extracted from Stack Overflow 2023 & Job Postings 2025 datasets.",
    skills: [
      {
        id: "w1",
        title: "Modern HTML5 & Semantic Web",
        category: "Frontend",
        description: "Accessibility (a11y), SEO tags, semantic structure.",
        difficulty: "Beginner",
        estimatedHours: 10,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "w2",
        title: "CSS3, Modern Layouts & Tailwind CSS",
        category: "Frontend",
        description: "Flexbox, Grid, keyframe animations, utility classes.",
        difficulty: "Beginner",
        estimatedHours: 15,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "w3",
        title: "JavaScript (ES6+) & Async Programming",
        category: "Frontend",
        description: "Promises, Async/Await, Fetch API, Closures, Modules.",
        difficulty: "Intermediate",
        estimatedHours: 25,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "w4",
        title: "React / Vue.js Framework Architecture",
        category: "Frontend",
        description: "Component lifecycles, state management, hooks, router.",
        difficulty: "Intermediate",
        estimatedHours: 35,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "w5",
        title: "Web Performance & Core Web Vitals",
        category: "Optimization",
        description: "Lighthouse metrics, code splitting, lazy loading, caching.",
        difficulty: "Advanced",
        estimatedHours: 20,
        isCompleted: false,
        prerequisites: []
      }
    ]
  },
  {
    id: "cloud_path",
    title: "Cloud Computing",
    iconName: "cloud",
    description: "Extracted from Stack Overflow 2023 & Job Postings 2025 datasets.",
    skills: [
      {
        id: "c1",
        title: "Linux Fundamentals & Shell Scripting",
        category: "Infrastructure",
        description: "Bash automation, file permissions, process management, SSH.",
        difficulty: "Beginner",
        estimatedHours: 15,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "c2",
        title: "Docker & Containerization",
        category: "DevOps",
        description: "Dockerfile composition, multi-stage builds, Docker Compose.",
        difficulty: "Beginner",
        estimatedHours: 20,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "c3",
        title: "AWS Core Services (EC2, S3, IAM, VPC)",
        category: "Cloud Infrastructure",
        description: "Virtual servers, cloud storage, security policies, networking.",
        difficulty: "Intermediate",
        estimatedHours: 35,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "c4",
        title: "Kubernetes Orchestration",
        category: "DevOps",
        description: "Pods, deployments, services, ingress controllers, Helm charts.",
        difficulty: "Advanced",
        estimatedHours: 40,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "c5",
        title: "Terraform Infrastructure as Code",
        category: "DevOps",
        description: "Declarative cloud provisioning, state management, modules.",
        difficulty: "Intermediate",
        estimatedHours: 25,
        isCompleted: false,
        prerequisites: []
      }
    ]
  },
  {
    id: "ml_path",
    title: "Machine Learning",
    iconName: "psychology",
    description: "Extracted from Stack Overflow 2023 & Job Postings 2025 datasets.",
    skills: [
      {
        id: "m1",
        title: "Python for Data Analysis (NumPy & Pandas)",
        category: "Data Engineering",
        description: "Data wrangling, feature extraction, tabular analysis.",
        difficulty: "Beginner",
        estimatedHours: 20,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "m2",
        title: "Classical Machine Learning (Scikit-Learn)",
        category: "Modeling",
        description: "Linear regression, decision trees, random forests, clustering.",
        difficulty: "Intermediate",
        estimatedHours: 30,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "m3",
        title: "SQL & Database Querying",
        category: "Data Engineering",
        description: "Complex joins, aggregation, indexing, window functions.",
        difficulty: "Beginner",
        estimatedHours: 15,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "m4",
        title: "Deep Learning with PyTorch",
        category: "Deep Learning",
        description: "Neural networks, CNNs, Transformers, model training loops.",
        difficulty: "Advanced",
        estimatedHours: 45,
        isCompleted: false,
        prerequisites: []
      },
      {
        id: "m5",
        title: "MLOps & Model Deployment",
        category: "Deployment",
        description: "REST API wrapping (FastAPI/Flask), model monitoring, MLflow.",
        difficulty: "Intermediate",
        estimatedHours: 25,
        isCompleted: false,
        prerequisites: []
      }
    ]
  }
];

async function seed() {
  console.log("Seeding Firestore career paths & skills...");
  for (const path of careerPaths) {
    await db.collection("career_paths").doc(path.id).set(path);
    console.log(`Seeded path: ${path.title}`);
  }
  console.log("Successfully seeded Firestore database!");
  process.exit(0);
}

seed().catch(err => {
  console.error("Seeding failed:", err);
  process.exit(1);
});
