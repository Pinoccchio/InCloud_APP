End-to-End Order Flow

  CUSTOMER (Mobile App)              ADMIN (Web App)
  │                                 │
  ├─ 1. Browse Products             │
  ├─ 2. Add to Cart                │
  ├─ 3. Select Pricing Tier         │
  ├─ 4. REQUEST Order ──────────────► ├─ 5. Receive Order Notification
  │                                 ├─ 6. Check Inventory Levels
  │                                 ├─ 7. Confirm Order
  │                                 ├─ 8. Reserve Stock
  │                                 ├─ 9. Prepare/Pack Items
  │                                 ├─ 10. Mark "In-Transit"
  ├─ 11. See "In-Transit" ◄────────┤
  │    (Real-time notification)     ├─ 12. Deliver to Branch
  ├─ 13. See "Delivered" ◄─────────┤ ├─ 14. Mark "Delivered"
  ├─ 15. Pay at Branch             │ ├─ 16. Receive Payment
  ├─ 17. View in Order History     │ ├─ 17. Mark "Paid"
  │                                 ├─ 18. Complete Order

  Key Points About the Order System:

  1. Traditional Business Model: No online payments - customers pay cash on
  delivery or at branch
  2. Request-Based: Customers "request" orders, admins "fulfill" them
  3. Single-Admin Operation: One admin team handles all orders (no complex
  assignment system)
  4. Real-time Sync: Status updates flow instantly between mobile and web apps        
  5. Inventory Integration: Stock is reserved upon confirmation, updated
  throughout process

  Payment Methods:

  - Cash on Delivery (Primary)
  - Branch Payment (Customer visits branch to pay)
  - Credit Terms (For wholesale customers with 7-30 day payment terms)