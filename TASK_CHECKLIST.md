# SmartCanteen - Implementation Checklist

> Copy checklist ini ke Project Management tool (Trello, Jira, GitHub Projects, atau Notion)

---

## 📌 PHASE 1: CRITICAL USER FLOWS (Week 1-2)

### T1.1 - User Home Page
- [ ] Create `lib/features/user/presentation/pages/user_home_page.dart`
- [ ] Create `MenuListWidget` untuk display menu items
- [ ] Create `CategoryFilterChip` component
- [ ] Integrate `MenuService.getAllMenus()` dengan StreamBuilder
- [ ] Implement search functionality
- [ ] Implement category filtering
- [ ] Add featured/promo section
- [ ] Add infinite scroll / pagination
- [ ] Add shimmer loading skeleton
- [ ] Add "no menus" empty state
- [ ] Add floating action button untuk filter/sort
- **Estimated**: 3-4 days

### T1.2 - Menu Detail Page
- [ ] Create `lib/features/user/presentation/pages/user_menu_detail_page.dart`
- [ ] Design menu detail layout (image carousel, info, ratings)
- [ ] Display menu details (name, price, description)
- [ ] Display average rating & review count
- [ ] Create quantity selector widget
- [ ] Implement "Add to Cart" button
- [ ] Show add to cart success snackbar
- [ ] Create "Related Items" section
- [ ] Add reviews list with pagination
- [ ] Add "Add Favorite" button
- **Estimated**: 3 days

### T1.3 - Shopping Cart Page
- [ ] Create `lib/features/user/presentation/pages/user_cart_page.dart`
- [ ] Display cart items dengan StreamBuilder
- [ ] Implement quantity +/- buttons
- [ ] Implement remove item button
- [ ] Calculate & display subtotal, tax, delivery fee
- [ ] Display final total price
- [ ] Add "Continue Shopping" button
- [ ] Add "Checkout" button
- [ ] Handle empty cart state
- [ ] Add item clear all confirmation
- **Estimated**: 2 days

### T1.4 - Checkout Page
- [ ] Create `lib/features/user/presentation/pages/user_checkout_page.dart`
- [ ] Create address input form (street, city, postal code, phone, notes)
- [ ] Implement address validation
- [ ] Add saved addresses list/selection
- [ ] Add "Use Current Location" button (optional)
- [ ] Delivery method selection (Standard/Express)
- [ ] Payment method selection (Radio buttons: QRIS/E-wallet/Tunai)
- [ ] Display order summary
- [ ] Add promo code input (optional)
- [ ] "Place Order" button → trigger `OrderService.createOrder()`
- [ ] Handle order creation loading/error states
- [ ] Navigate to payment page or order confirmation
- **Estimated**: 4 days

---

## 💳 PHASE 2: PAYMENT INTEGRATION (Week 3)

### T2.1 - Payment Gateway Setup
- [ ] Research payment providers (Midtrans/Xendit/Stripe)
- [ ] Decide on provider for Indonesia market
- [ ] Create payment provider account & get credentials
- [ ] Add payment package to `pubspec.yaml`
- [ ] Create `PaymentService` wrapper class
- [ ] Setup payment gateway configuration
- [ ] Test payment gateway credentials
- **Estimated**: 2-3 days

### T2.2 - QRIS Payment Flow
- [ ] Generate QRIS/QR code payload dari OrderService
- [ ] Create payment confirmation page dengan QR display
- [ ] Integrate QR code display widget
- [ ] Setup payment status callback listener
- [ ] Update order status di Firestore (pending → processing)
- [ ] Show payment success confirmation
- [ ] Handle payment failure / timeout
- [ ] Generate receipt / order confirmation
- **Estimated**: 3 days

### T2.3 - Alternative Payment Methods
- [ ] Implement E-wallet payment flow
- [ ] Implement Cash on Delivery flow
- [ ] Implement payment method fallback logic
- [ ] Add payment retry mechanism
- **Estimated**: 2 days

---

## 🔔 PHASE 3: REAL-TIME FEATURES (Week 4)

### T3.1 - Real-time Order Status Updates
- [ ] Create `lib/features/user/presentation/pages/user_orders_page.dart`
- [ ] Setup StreamBuilder dengan `OrderService.streamUserOrders()`
- [ ] Create `OrderCard` widget untuk list display
- [ ] Display status badge (pending/processing/ready/completed)
- [ ] Add order timestamp display
- [ ] Create order detail bottom sheet / page
- [ ] Display order items & total price
- [ ] Add order tracking UI (timeline visualization)
- [ ] Add pull-to-refresh functionality
- [ ] Add filter by status tabs
- [ ] Handle empty orders state
- **Estimated**: 3 days

### T3.2 - Real-time Chat System
- [ ] Create `ChatService` untuk message management
- [ ] Create `lib/features/user/presentation/pages/user_chat_page.dart`
- [ ] Create `lib/features/admin/presentation/pages/admin_chat_page.dart`
- [ ] Setup StreamBuilder untuk real-time chat listener
- [ ] Create message bubble widget (sent/received styles)
- [ ] Implement message send functionality
- [ ] Add message input field with validation
- [ ] Add timestamp untuk each message
- [ ] Add read status indicator
- [ ] Add typing indicator (optional)
- [ ] Handle connection/offline states
- **Estimated**: 4 days

### T3.3 - Push Notifications
- [ ] Request user notification permission
- [ ] Get device FCM token dari Firebase Messaging
- [ ] Store FCM token di Firestore user document
- [ ] Create notification handler untuk incoming messages
- [ ] Setup notification routing (deep linking)
- [ ] Create NotificationService wrapper
- [ ] Test push notifications dari Firebase Console
- [ ] Add local notification display
- [ ] Create notification history page
- **Estimated**: 3-4 days

---

## 👨‍💼 PHASE 4: ADMIN FEATURES (Week 5)

### T4.1 - Admin Order Management
- [ ] Create `lib/features/admin/presentation/pages/admin_orders_page.dart`
- [ ] Setup StreamBuilder untuk real-time orders list
- [ ] Create `AdminOrderCard` widget
- [ ] Display order status dengan color coding
- [ ] Add filter tabs (All/Pending/Processing/Ready/Completed)
- [ ] Add search by order ID / customer name
- [ ] Create order detail modal/page
- [ ] Add payment verification checkbox
- [ ] Implement status update UI (dropdown / action buttons)
- [ ] Update order status → trigger Firestore update
- [ ] Notify user saat status berubah (via notification)
- [ ] Add order cancellation handling
- [ ] Add order timestamp filters
- **Estimated**: 4 days

### T4.2 - Admin Menu Management
- [ ] Create `lib/features/admin/presentation/pages/admin_menu_page.dart`
- [ ] Display menus list dengan pagination
- [ ] Create add menu modal/page
- [ ] Create edit menu modal/page
- [ ] Create delete menu confirmation
- [ ] Implement menu form (name, description, price, category)
- [ ] Add category selection dropdown
- [ ] Add availability toggle
- [ ] Implement stock/quantity field
- [ ] Add category management section
- [ ] Search menus functionality
- [ ] Image upload untuk menu items
- **Estimated**: 4 days

### T4.3 - Admin Chat
- [ ] Create `lib/features/admin/presentation/pages/admin_chat_page.dart`
- [ ] Display chat list dengan customer names
- [ ] Show unread message count / badge
- [ ] Setup real-time chat listener
- [ ] Create message thread view
- [ ] Implement message send untuk admin
- [ ] Add customer info header (name, phone, recent order)
- [ ] Add notification untuk new messages
- [ ] Mark messages as read
- **Estimated**: 3 days

### T4.4 - Admin Statistics & Reports
- [ ] Create statistics page dengan charts
- [ ] Display daily sales chart (fl_chart integration)
- [ ] Display weekly/monthly sales trends
- [ ] Show top selling items chart
- [ ] Show revenue breakdown
- [ ] Calculate order completion rate
- [ ] Show payment method breakdown pie chart
- [ ] Add date range filter
- [ ] Add export/download reports (optional)
- [ ] Add customer statistics
- **Estimated**: 4 days

---

## ⭐ PHASE 5: RATINGS & RECOMMENDATIONS (Week 6)

### T5.1 - Rating System
- [ ] Create `RatingService` class
- [ ] Add rating submission UI (modal/page) di user_orders_page
- [ ] Create star rating selector component (1-5 stars)
- [ ] Add review text input field
- [ ] Add optional photo upload untuk review
- [ ] Persist rating ke Firestore dengan user/menu/order reference
- [ ] Create average rating calculation function
- [ ] Display avg rating pada menu cards
- [ ] Create reviews list component
- [ ] Display reviews pada menu detail page
- **Estimated**: 3 days

### T5.2 - Recommendation System
- [ ] Design recommendation algorithm (collaborative filtering / content-based)
- [ ] Create `RecommendationService` class
- [ ] Collect user behavior data (purchases, ratings, favorites)
- [ ] Implement recommendation calculation
- [ ] Cache recommendations di Firestore
- [ ] Create recommendations section di home page
- [ ] Display recommended items dengan "Recommended for you" label
- [ ] Add A/B testing untuk recommendation accuracy (optional)
- **Estimated**: 4-5 days (requires backend logic)

---

## 🎨 PHASE 6: POLISH & OPTIMIZATION (Week 7)

### T6.1 - Image Upload & Handling
- [ ] Setup Firebase Storage bucket
- [ ] Create image picker integration (camera/gallery)
- [ ] Implement image compression
- [ ] Upload images ke Firebase Storage
- [ ] Store image URLs di Firestore
- [ ] Implement cached network image everywhere
- [ ] Add image loading skeleton
- [ ] Add image upload error handling
- **Estimated**: 2 days

### T6.2 - Error Handling & Validation
- [ ] Create global error handler/logger
- [ ] Add validation untuk semua form inputs
- [ ] Implement network error detection
- [ ] Create error UI/snackbar components
- [ ] Add retry logic untuk failed operations
- [ ] Implement timeout handling
- [ ] Add user-friendly error messages
- **Estimated**: 2 days

### T6.3 - Performance Optimization
- [ ] Lazy load images dalam list views
- [ ] Implement pagination untuk long lists
- [ ] Optimize Firestore queries (add indices)
- [ ] Reduce bundle size
- [ ] Implement state management best practices
- [ ] Profile app performance dengan DevTools
- [ ] Fix any performance bottlenecks
- **Estimated**: 2 days

### T6.4 - Testing
- [ ] Write unit tests untuk services
- [ ] Write widget tests untuk custom components
- [ ] Write integration tests untuk critical flows
- [ ] Manual testing checklist
- [ ] Bug fix iteration
- **Estimated**: 3 days

---

## 🔧 INFRASTRUCTURE & SETUP

### Firebase Setup
- [ ] ✅ Firebase project created (smartcanteen-49b04)
- [ ] ✅ Firebase Auth configured
- [ ] ✅ Firestore database created dengan collections
- [ ] ⚠️ Firestore Security Rules - NEED TO VERIFY
  - [ ] User can only read/write own data
  - [ ] Admin can read/write orders & menus
  - [ ] Public read untuk menus & categories
- [ ] ⚠️ Firebase Storage bucket - NEED TO CONFIGURE
- [ ] ⚠️ Firebase Cloud Messaging (FCM) - NEED TO SETUP
- [ ] ⚠️ Firebase Functions (for backend logic) - OPTIONAL

### Dependencies Management
- [ ] ✅ pubspec.yaml configured dengan basic packages
- [ ] [ ] Add payment provider package (midtrans_flutter / xendit_flutter)
- [ ] [ ] Verify all package versions compatibility
- [ ] [ ] Run `flutter pub get` & `flutter pub upgrade`
- [ ] [ ] Check for any package vulnerabilities

### Development Environment
- [ ] Android build configured
- [ ] iOS build configured (if needed)
- [ ] Firebase credentials secure (not in git)
- [ ] Environment variables setup
- [ ] Development vs Production configurations

---

## 📱 TESTING CHECKLIST

### User Flow Testing
- [ ] [ ] User dapat login dengan email/password
- [ ] [ ] User dapat register akun baru
- [ ] [ ] User diarahkan ke home page setelah login
- [ ] [ ] Home page menampilkan menu items dengan benar
- [ ] [ ] User dapat search & filter menus
- [ ] [ ] User dapat melihat menu detail
- [ ] [ ] User dapat add items to cart
- [ ] [ ] User dapat melihat cart & modify quantities
- [ ] [ ] User dapat checkout dengan address & payment method
- [ ] [ ] User menerima order confirmation
- [ ] [ ] User dapat track order status real-time
- [ ] [ ] User dapat chat dengan customer service
- [ ] [ ] User dapat memberi rating setelah order
- [ ] [ ] User dapat logout

### Admin Flow Testing
- [ ] [ ] Admin dapat login dengan credentials
- [ ] [ ] Admin dashboard menampilkan correct statistics
- [ ] [ ] Admin dapat melihat incoming orders real-time
- [ ] [ ] Admin dapat update order status
- [ ] [ ] User notified saat admin update status
- [ ] [ ] Admin dapat manage menu items (add/edit/delete)
- [ ] [ ] Admin dapat chat dengan users
- [ ] [ ] Admin dapat melihat statistics & charts
- [ ] [ ] Admin dapat logout

### Edge Cases
- [ ] [ ] App handles network disconnection gracefully
- [ ] [ ] App handles payment failure scenarios
- [ ] [ ] App handles empty states (no orders, no menus, etc)
- [ ] [ ] App handles concurrent user actions
- [ ] [ ] App handles timeout scenarios

---

## 🚀 DEPLOYMENT CHECKLIST

### Before Release
- [ ] All critical features implemented & tested
- [ ] Zero critical bugs
- [ ] Performance optimized
- [ ] Security reviewed
- [ ] Firebase rules properly configured
- [ ] Payment gateway credentials secured
- [ ] Analytics setup
- [ ] Logging setup

### Release Steps
- [ ] Build Android APK
- [ ] Build iOS IPA (if needed)
- [ ] Test on real devices
- [ ] Submit to Play Store / App Store
- [ ] Monitor crash reports
- [ ] Collect user feedback

---

## 📊 TRACKING

### Status Legend
- ✅ = Completed
- ⚠️ = In Progress / Partial
- ❌ = Not Started
- 🔄 = In Review / QA

### Update Template
```
Date: YYYY-MM-DD
Phase: [Phase number]
Completed: [number] tasks
In Progress: [number] tasks
Blocker: [if any]
Next Sprint: [what's next]
```

---

**Last Updated**: 2026-06-07  
**Version**: 1.0  
**Prepared for**: Development Sprint Planning
