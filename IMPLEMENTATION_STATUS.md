# SmartCanteen - Implementation Status & Task List

## 📋 ANALISIS ALUR KERJA vs IMPLEMENTASI SAAT INI

### ✅ ALUR YANG SUDAH SESUAI

#### 1. **User Authentication Flow** ✅
- [x] User membuka aplikasi → Splash screen
- [x] Navigasi ke halaman login/register sesuai kondisi auth
- [x] Login/Register dengan validasi email & password
- [x] Role selection (admin/user)
- [x] Admin login dengan role verification
- [x] Auto-login menggunakan token & SharedPreferences
- [x] Logout functionality

**Location**: `features/autentikasi/`

---

#### 2. **Admin Order Dashboard** ✅
- [x] Dashboard menampilkan statistik (total orders, revenue, menus)
- [x] Pending orders counter
- [x] Real-time order status tracking (via OrderService)
- [x] Admin dapat melihat detail pesanan

**Location**: `features/admin/presentation/pages/admin_dashboard_page.dart`

---

#### 3. **Backend Infrastructure** ✅
- [x] Firebase Auth setup
- [x] Firestore collections (users, menus, categories, orders, carts, chats, notifications)
- [x] API Service structure (ready untuk REST API integration)
- [x] Cart management service
- [x] Order management service
- [x] Menu management service
- [x] Real-time stream support via Firestore listeners

**Location**: `core/services/`

---

### ⚠️ FITUR YANG BELUM LENGKAP / PARTIAL

| Fitur | Status | Gap | Priority |
|-------|--------|-----|----------|
| **User Home Page** | UI skeleton | Belum integrasi menu display, search, filter, recommendations | HIGH |
| **Menu Detail Page** | UI skeleton | Belum detail display, rating, add to cart flow | HIGH |
| **Shopping Cart** | Service OK ✅ | UI belum diimplementasi | HIGH |
| **Checkout Process** | Service skeleton | Belum form alamat, payment method selection, order creation | HIGH |
| **Payment Integration** | Not started | QRIS/E-wallet/Cash processor belum ada | HIGH |
| **Real-time Updates** | Partial | Order status update ke user belum UI | MEDIUM |
| **Chat Feature** | Service OK ✅ | UI + Firestore listener belum | MEDIUM |
| **Notifications** | Firebase setup | Local + push notifications UI belum | MEDIUM |
| **AI Recommendations** | Completed | Fully implemented, integrated, and cached | MEDIUM |
| **Ratings & Reviews** | Not started | Rating submission + display belum | MEDIUM |
| **Admin Menu Management** | UI skeleton | CRUD menu operations belum | MEDIUM |
| **Admin Orders Management** | Service OK ✅ | UI + status update UI belum | MEDIUM |
| **Image Upload** | Not started | Firebase Storage integration belum | LOW |
| **Order Tracking** | Partial | Real-time map tracking belum | LOW |

---

## ❌ FITUR YANG BELUM DIIMPLEMENTASIKAN

### 1. **User Flows - CRITICAL**

#### User Home Page
- [ ] Display list of menus dengan pagination
- [ ] Display categories
- [ ] Search functionality
- [ ] Filter by category
- [ ] Display promos/featured items
- [ ] AI-powered recommendations display
- [ ] Menu card dengan quick-add to cart

#### Menu Detail Page
- [ ] Full menu details (name, description, price, images)
- [ ] Star ratings & review count
- [ ] Customer reviews display
- [ ] Add to cart with quantity selector
- [ ] Related/suggested items

#### Shopping Cart
- [ ] Display cart items
- [ ] Increase/decrease item quantity
- [ ] Remove items
- [ ] Persistent cart state
- [ ] Total price calculation
- [ ] Checkout button

#### Checkout Process
- [ ] Address selection/input form
- [ ] Address validation
- [ ] Delivery method selection
- [ ] Payment method selection (QRIS/E-wallet/Tunai)
- [ ] Order summary
- [ ] Order creation trigger
- [ ] Payment processing

#### Payment Integration
- [ ] QRIS QR code generation & display
- [ ] E-wallet payment processing
- [ ] Cash on delivery handling
- [ ] Payment verification callback
- [ ] Transaction status tracking
- [ ] Receipt generation

#### User Orders Page
- [ ] List user's orders
- [ ] Order status display (pending → processing → ready → completed)
- [ ] Real-time status updates
- [ ] Order details view
- [ ] Cancel order functionality
- [ ] Delivery tracking (if applicable)

#### User Chat
- [ ] Chat UI with message list
- [ ] Real-time message Firestore listener
- [ ] Send message functionality
- [ ] Message timestamp display
- [ ] Unread message indicator
- [ ] Chat with customer service

#### User Profile
- [ ] Display user info (name, email, phone)
- [ ] Edit profile form
- [ ] Change password
- [ ] Saved addresses
- [ ] Order history summary
- [ ] Logout button

#### Ratings & Reviews
- [ ] Rating submission UI (after order completion)
- [ ] Star rating component (1-5)
- [ ] Review text input
- [ ] Photo upload for review
- [ ] Ratings persistence to Firestore
- [ ] Display ratings on menu detail

---

### 2. **Admin Flows - CRITICAL**

#### Admin Menu Management
- [ ] List all menus
- [ ] Add new menu form
- [ ] Edit menu details
- [ ] Delete menu
- [ ] Category management
- [ ] Image upload for menus
- [ ] Availability toggle
- [ ] Price management

#### Admin Orders Management
- [ ] Real-time orders list
- [ ] Filter orders by status
- [ ] Order detail view
- [x] Verify payment
- [ ] Update order status (pending → processing → ready → completed)
- [ ] Notify user on status change
- [ ] Order cancellation handling
- [ ] Order search/filter

#### Admin Chat
- [ ] List ongoing chats
- [ ] Chat history view
- [ ] Real-time message listener
- [ ] Send message to customer
- [ ] Chat response notification
- [ ] Close chat session

#### Admin Notifications
- [ ] Push notification for new orders
- [ ] Status change notifications
- [ ] Chat message notifications
- [ ] Notification history
- [ ] Mark as read

#### Admin Statistics
- [ ] Daily/weekly/monthly sales
- [ ] Most sold items
- [ ] Revenue charts
- [ ] Customer statistics
- [ ] Order completion rate
- [ ] Payment method breakdown

#### Admin Profile
- [ ] Display admin info
- [ ] Change password
- [ ] Notification preferences
- [ ] Logout

---

### 3. **Real-time Features - IMPORTANT**

#### Real-time Order Status Updates
- [ ] Firestore listener untuk order status changes
- [ ] Push notification saat status berubah
- [ ] UI update tanpa refresh
- [ ] Timestamp tracking untuk setiap status

#### Real-time Chat
- [ ] Firestore real-time listener
- [ ] Message delivery confirmation
- [ ] Typing indicator
- [ ] Online status indicator

#### Real-time Notifications
- [ ] Firebase Cloud Messaging (FCM) setup
- [ ] Local notifications display
- [ ] Notification center UI
- [ ] Deep linking dari notification ke relevant page

---

### 4. **AI & Recommendation System - IMPORTANT**

#### Recommendation Algorithm
- [ ] Collect user behavior data (purchases, ratings, favorites)
- [ ] Implement collaborative filtering / content-based filtering
- [ ] Generate personalized recommendations
- [ ] Display recommendations on home page
- [ ] A/B testing untuk recommendation accuracy

#### Rating System
- [ ] Rating submission after order
- [ ] Rating data persistence
- [ ] Avg rating calculation
- [ ] Rating display on menu card & detail page

---

### 5. **Payment System - CRITICAL**

#### QRIS/QR Payment
- [ ] Generate QRIS from payment amount
- [ ] Display QR code to user
- [ ] QR scanning verification (optional for user)
- [ ] Payment status callback from gateway
- [ ] Transaction receipt

#### E-Wallet Integration
- [ ] E-wallet gateway integration
- [ ] Payment form with amount
- [ ] Payment callback handling
- [ ] Transaction status tracking

#### Cash Payment
- [ ] Mark order as "waiting for cash"
- [ ] Admin confirmation saat uang diterima
- [ ] Payment status update

---

### 6. **Media & Upload - MEDIUM**

#### Image Upload
- [ ] Camera/gallery picker
- [ ] Image compression
- [ ] Upload to Firebase Storage
- [ ] Store URL di Firestore
- [ ] Cached network image display

#### Image Management
- [ ] Menu images
- [ ] User profile images
- [ ] Review photos

---

### 7. **Advanced Features - NICE TO HAVE**

#### Offline Mode
- [ ] Local caching of menus
- [ ] Offline cart persistence
- [ ] Sync saat online
- [ ] Offline availability status

#### Order Tracking
- [ ] Real-time GPS tracking (if applicable)
- [ ] Map display of delivery location
- [ ] Estimated delivery time

#### Analytics
- [ ] Firebase Analytics events
- [ ] User engagement tracking
- [ ] Sales metrics dashboard

#### Performance Optimization
- [ ] Image optimization
- [ ] Lazy loading
- [ ] Database indexing
- [ ] Query optimization

---

## 🎯 TASK LIST - IMPLEMENTATION PRIORITY

### **PHASE 1: CRITICAL USER FLOWS (Weeks 1-2)**

#### Priority 1.1 - User Home & Menu Display
- [ ] T1.1.1: Create user_home_page.dart with menu list
- [ ] T1.1.2: Integrate MenuService to fetch & display menus
- [ ] T1.1.3: Implement category filter chip component
- [ ] T1.1.4: Create search functionality
- [ ] T1.1.5: Display featured/promo items
- [ ] T1.1.6: Implement infinite scroll pagination

#### Priority 1.2 - Menu Detail & Add to Cart
- [ ] T1.2.1: Create user_menu_detail_page.dart
- [ ] T1.2.2: Display menu details (images, price, description)
- [ ] T1.2.3: Implement quantity selector
- [ ] T1.2.4: Add "Add to Cart" button with CartService integration
- [ ] T1.2.5: Display reviews & ratings
- [ ] T1.2.6: Implement "Add to Favorites" functionality

#### Priority 1.3 - Shopping Cart UI
- [ ] T1.3.1: Create user_cart_page.dart
- [ ] T1.3.2: Display cart items dari CartService
- [ ] T1.3.3: Implement quantity +/- buttons
- [ ] T1.3.4: Implement remove item button
- [ ] T1.3.5: Calculate & display total price
- [ ] T1.3.6: Implement "Continue Shopping" & "Checkout" buttons

#### Priority 1.4 - Checkout & Order Creation
- [ ] T1.4.1: Create user_checkout_page.dart
- [ ] T1.4.2: Address input form dengan validation
- [ ] T1.4.3: Payment method selection (QRIS/E-wallet/Tunai)
- [ ] T1.4.4: Order summary display
- [ ] T1.4.5: Create order via OrderService
- [ ] T1.4.6: Clear cart after successful order

---

### **PHASE 2: PAYMENT INTEGRATION (Week 3)**

#### Priority 2.1 - Payment Gateway Setup
- [ ] T2.1.1: Research & select payment provider (Midtrans/Xendit/etc)
- [ ] T2.1.2: Setup payment gateway account & credentials
- [ ] T2.1.3: Add payment package to pubspec.yaml
- [ ] T2.1.4: Create PaymentService wrapper

#### Priority 2.2 - QRIS Payment Implementation
- [ ] T2.2.1: Generate QRIS payload dari OrderService
- [ ] T2.2.2: Display QR code di checkout page
- [ ] T2.2.3: Implement payment status callback handler
- [ ] T2.2.4: Update order status di Firestore
- [ ] T2.2.5: Show payment confirmation

#### Priority 2.3 - Alternative Payment Methods
- [ ] T2.3.1: Implement E-wallet payment flow
- [ ] T2.3.2: Implement Cash payment handling
- [ ] T2.3.3: Payment method fallback logic

---

### **PHASE 3: REAL-TIME FEATURES (Week 4)**

#### Priority 3.1 - Real-time Order Status
- [ ] T3.1.1: Create user_orders_page.dart
- [ ] T3.1.2: Setup StreamBuilder dengan OrderService.streamUserOrders()
- [ ] T3.1.3: Display order list dengan status badge
- [ ] T3.1.4: Create order detail bottom sheet/dialog
- [ ] T3.1.5: Implement order refresh functionality

#### Priority 3.2 - Real-time Chat System
- [ ] T3.2.1: Create ChatService untuk real-time messaging
- [ ] T3.2.2: Create user_chat_page.dart & admin_chat_page.dart
- [ ] T3.2.3: Implement StreamBuilder untuk Firestore chats
- [ ] T3.2.4: Message send/receive functionality
- [ ] T3.2.5: Message timestamp & read status

#### Priority 3.3 - Push Notifications
- [ ] T3.3.1: Setup Firebase Cloud Messaging (FCM)
- [ ] T3.3.2: Request user notification permission
- [ ] T3.3.3: Get device FCM token & store di Firestore
- [ ] T3.3.4: Send notification dari admin untuk status updates
- [ ] T3.3.5: Deep linking ke order detail page dari notification

---

### **PHASE 4: ADMIN FEATURES (Week 5)**

#### Priority 4.1 - Admin Order Management
- [ ] T4.1.1: Implement admin_orders_page.dart
- [ ] T4.1.2: Real-time orders list dengan StreamBuilder
- [ ] T4.1.3: Order status update UI (dropdown/buttons)
- [ ] T4.1.4: Order detail modal
- [x] T4.1.5: Payment verification checkbox
- [ ] T4.1.6: Notify user saat status change

#### Priority 4.2 - Admin Menu Management
- [ ] T4.2.1: Implement admin_menu_page.dart
- [ ] T4.2.2: Menu list dengan add/edit/delete buttons
- [ ] T4.2.3: Create menu form modal
- [ ] T4.2.4: Image upload untuk menu
- [ ] T4.2.5: Category management
- [ ] T4.2.6: Availability toggle

#### Priority 4.3 - Admin Chat
- [ ] T4.3.1: Implement admin_chat_page.dart
- [ ] T4.3.2: List ongoing chats dengan unread count
- [ ] T4.3.3: Real-time message listener
- [ ] T4.3.4: Send message functionality
- [ ] T4.3.5: Chat notification

#### Priority 4.4 - Admin Statistics
- [ ] T4.4.1: Create statistics page dengan charts
- [ ] T4.4.2: Daily/weekly/monthly sales data
- [ ] T4.4.3: Top selling items
- [ ] T4.4.4: Order completion rate
- [ ] T4.4.5: Payment method breakdown

---

### **PHASE 5: RATINGS & RECOMMENDATIONS (Week 6)**

#### Priority 5.1 - Rating System
- [ ] T5.1.1: Create RatingService
- [ ] T5.1.2: Rating submission UI (stars + text)
- [ ] T5.1.3: Persist ratings to Firestore
- [ ] T5.1.4: Display avg rating on menu cards
- [ ] T5.1.5: Display review list on menu detail

#### Priority 5.2 - Recommendation System
- [x] T5.2.1: Design recommendation algorithm
- [x] T5.2.2: Create RecommendationService
- [x] T5.2.3: Collect user behavior (purchase history, ratings)
- [x] T5.2.4: Generate recommendations
- [x] T5.2.5: Display on home page
- [ ] T5.2.6: A/B test recommendation accuracy

---

### **PHASE 6: POLISH & OPTIMIZATION (Week 7)**

#### Priority 6.1 - Image Handling
- [ ] T6.1.1: Firebase Storage setup
- [ ] T6.1.2: Image upload widget
- [ ] T6.1.3: Image compression before upload
- [ ] T6.1.4: Image caching strategy

#### Priority 6.2 - Error Handling & Validation
- [ ] T6.2.1: Global error handler
- [ ] T6.2.2: Input validation untuk semua forms
- [ ] T6.2.3: Network error handling
- [ ] T6.2.4: User-friendly error messages

#### Priority 6.3 - Performance
- [ ] T6.3.1: Lazy loading di list views
- [ ] T6.3.2: Image lazy loading
- [ ] T6.3.3: Firestore query optimization
- [ ] T6.3.4: Memory optimization

#### Priority 6.4 - Testing
- [ ] T6.4.1: Unit tests untuk services
- [ ] T6.4.2: Widget tests untuk UI components
- [ ] T6.4.3: Integration tests untuk flows
- [ ] T6.4.4: Load testing untuk concurrent users

---

## 📊 SUMMARY TABLE

| Phase | Focus | Duration | Tasks |
|-------|-------|----------|-------|
| **Phase 1** | Critical User Flows | 2 weeks | 20 tasks |
| **Phase 2** | Payment Integration | 1 week | 8 tasks |
| **Phase 3** | Real-time Features | 1 week | 10 tasks |
| **Phase 4** | Admin Features | 1 week | 15 tasks |
| **Phase 5** | Ratings & AI | 1 week | 10 tasks |
| **Phase 6** | Polish & Optimization | 1 week | 12 tasks |
| **TOTAL** | Full Implementation | **7 weeks** | **75+ tasks** |

---

## 🚀 RECOMMENDED NEXT STEPS

### Immediate (Today)
1. [ ] Prioritize & approve task list dengan stakeholders
2. [ ] Setup project management tool (Trello/Jira/GitHub Projects)
3. [ ] Create development environment checklist

### This Week (Phase 1 Start)
1. [ ] Implement user_home_page dengan menu display
2. [ ] Integrate search & filter functionality
3. [ ] Create menu detail page
4. [ ] Implement add to cart flow

### By End of Month
1. [ ] Full user checkout flow working
2. [ ] Payment integration live
3. [ ] Real-time order tracking
4. [ ] Admin order management

---

## 📝 NOTES

- Semua task diasumsikan menggunakan existing services (OrderService, CartService, MenuService)
- Firebase Firestore real-time listeners sudah siap digunakan
- Payment gateway perlu dipilih berdasarkan requirement & region
- Recommendation algorithm perlu backend support (bisa menggunakan Firebase Functions atau separate Python service)
- Testing harus dilakukan di setiap phase untuk ensure quality

---

**Last Updated**: 2026-06-07  
**Status**: Ready for Implementation  
**Approved By**: -
