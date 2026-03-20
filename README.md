# NEU Library Project 📚

A modern library management web application developed as part of the Information Technology curriculum at **New Era University**. This project focuses on efficient data handling, secure authentication, and seamless database integration.

[![Vite](https://img.shields.io/badge/Vite-646CFF?style=for-the-badge&logo=vite&logoColor=white)](https://vitejs.dev/)
[![React](https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com/)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-4285F4?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/)
[![Vercel](https://img.shields.io/badge/Vercel-000000?style=for-the-badge&logo=vercel&logoColor=white)](https://vercel.com/)

---

## 🚀 Live Demo
🔗 **[neu-library-project.vercel.app](https://neu-library-project.vercel.app/)**

> **Note:** If you encounter a "Connection not private" error, it may be due to local ISP filtering of Vercel subdomains. Using a different network (like mobile data) or enabling DNS-over-HTTPS in your browser resolves this.

---

## ✨ Key Features

* **Integrated Google Authentication:** Secure login using Google OAuth 2.0 via Supabase.
* **Domain-Restricted Admin Access:**
    * **Students/General Users:** Can sign in with any valid Google account to browse library resources.
    * **Administrators:** Elevated dashboard access and management tools are automatically granted specifically to users with an `@neu.edu.ph` email address.
* **Library Management System:** Full CRUD functionality for managing book inventories, student records, and transaction logs.
* **Real-time Database:** Instant UI updates when book availability changes, powered by Supabase PostgreSQL.

---

## 🛠 Tech Stack

### **Frontend**
* **React.js (via Vite):** For building a fast, component-based user interface.
* **CSS / Tailwind:** Modern styling and responsive layout for mobile and desktop.

### **Backend & Security**
* **Supabase Auth:** Handles session management and JWT tokens.
* **Google OAuth 2.0:** Integrated for "One-Tap" and popup sign-in functionality.
* **Role-Based Access Control (RBAC):** Logic implemented to differentiate between general users and administrative users based on email domain.

### **Database & Hosting**
* **Supabase (PostgreSQL):** Cloud-hosted database for book and user data.
* **Vercel:** Hosting platform with Continuous Deployment (CD) from GitHub.

---

## 👨‍💻 Author
**Johann Riel S. Esquejo** *BS Information Technology (2BSIT-5)* New Era University

---

## 🛠 Installation & Local Setup

To run this project locally, follow these steps:

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/johannrielesquejo/NEU-Library-Project.git](https://github.com/johannrielesquejo/NEU-Library-Project.git)

https://neu-library-project.vercel.app

