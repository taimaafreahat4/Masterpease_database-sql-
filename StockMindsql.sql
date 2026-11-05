-- StockMind database: simple classroom-style SQL Server syntax.
-- All relationships are written directly inside CREATE TABLE.
-- Run on a NEW database only; existing tables must not be recreated.
IF DB_ID(N'StockMindDB') IS NULL
    CREATE DATABASE StockMindDB;
GO
USE StockMindDB;
GO

CREATE TABLE Roles (
    RoleID INT IDENTITY(1,1) PRIMARY KEY,
    RoleName NVARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE Users (
    UserID BIGINT IDENTITY(1,1) PRIMARY KEY,
    RoleID INT NOT NULL REFERENCES Roles(RoleID),
    FullName NVARCHAR(150) NOT NULL,
    Email NVARCHAR(255) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    Phone NVARCHAR(30) NULL,
    AvatarUrl NVARCHAR(1000) NULL,
    AccountStatus NVARCHAR(20) NOT NULL DEFAULT N'active',
    EmailVerified BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (AccountStatus IN (N'active',N'suspended',N'disabled'))
);

CREATE TABLE Addresses (
    AddressID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NOT NULL REFERENCES Users(UserID),
    RecipientName NVARCHAR(150) NOT NULL,
    Phone NVARCHAR(30) NULL,
    Country NVARCHAR(100) NOT NULL,
    City NVARCHAR(100) NOT NULL,
    StreetAddress NVARCHAR(400) NOT NULL,
    PostalCode NVARCHAR(30) NULL,
    IsDefault BIT NOT NULL DEFAULT 0
);

CREATE TABLE SellerProfiles (
    SellerID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NOT NULL UNIQUE REFERENCES Users(UserID),
    StoreName NVARCHAR(180) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    LogoUrl NVARCHAR(1000) NULL,
    Country NVARCHAR(100) NULL,
    City NVARCHAR(100) NULL,
    LocationDetails NVARCHAR(400) NULL,
    BusinessCategory NVARCHAR(60) NULL,
    StoreType NVARCHAR(40) NULL,
    TargetCustomers NVARCHAR(60) NULL,
    AverageVisitorsPerDay INT NULL,
    VerificationStatus NVARCHAR(20) NOT NULL DEFAULT N'pending',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (AverageVisitorsPerDay IS NULL OR AverageVisitorsPerDay >= 0),
    CHECK (VerificationStatus IN (N'pending',N'approved',N'rejected'))
);

CREATE TABLE Categories (
    CategoryID INT IDENTITY(1,1) PRIMARY KEY,
    ParentCategoryID INT NULL REFERENCES Categories(CategoryID),
    CategoryName NVARCHAR(120) NOT NULL UNIQUE,
    IsActive BIT NOT NULL DEFAULT 1
);

CREATE TABLE Products (
    ProductID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SellerID BIGINT NOT NULL REFERENCES SellerProfiles(SellerID),
    CategoryID INT NOT NULL REFERENCES Categories(CategoryID),
    ProductName NVARCHAR(200) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ProductCondition NVARCHAR(30) NOT NULL DEFAULT N'New',
    ApprovalStatus NVARCHAR(20) NOT NULL DEFAULT N'pending',
    SubmittedAt DATETIME2 NULL,
    ReviewedByUserID BIGINT NULL REFERENCES Users(UserID),
    ReviewedAt DATETIME2 NULL,
    RejectionReason NVARCHAR(1000) NULL,
    SKU NVARCHAR(80) NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT N'draft',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (ApprovalStatus IN (N'pending',N'approved',N'rejected')),
    CHECK (Status IN (N'draft',N'active',N'inactive',N'archived'))
);

CREATE TABLE ProductImages (
    ImageID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID BIGINT NOT NULL REFERENCES Products(ProductID),
    ImageUrl NVARCHAR(1000) NOT NULL,
    IsPrimary BIT NOT NULL DEFAULT 0,
    SortOrder INT NOT NULL DEFAULT 0
);

CREATE TABLE Inventory (
    InventoryID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID BIGINT NOT NULL UNIQUE REFERENCES Products(ProductID),
    AvailableQuantity INT NOT NULL DEFAULT 0,
    ReservedQuantity INT NOT NULL DEFAULT 0,
    ReorderLevel INT NOT NULL DEFAULT 0,
    UnitCost DECIMAL(12,2) NULL,
    LastUpdated DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (AvailableQuantity >= 0 AND ReservedQuantity >= 0 AND ReorderLevel >= 0),
    CHECK (UnitCost IS NULL OR UnitCost >= 0)
);

CREATE TABLE Listings (
    ListingID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ProductID BIGINT NOT NULL REFERENCES Products(ProductID),
    SellingMethod NVARCHAR(20) NOT NULL DEFAULT N'regular',
    UnitPrice DECIMAL(12,2) NULL,
    LotPrice DECIMAL(12,2) NULL,
    LotUnits INT NULL,
    MinOrderQuantity INT NOT NULL DEFAULT 1,
    ListingQuantity INT NOT NULL DEFAULT 0,
    Status NVARCHAR(20) NOT NULL DEFAULT N'draft',
    PublishedAt DATETIME2 NULL,
    ExpiresAt DATETIME2 NULL,
    CHECK (SellingMethod IN (N'regular',N'whole_lot')),
    CHECK (Status IN (N'draft',N'active',N'paused',N'sold',N'archived')),
    CHECK (MinOrderQuantity >= 1 AND ListingQuantity >= 0 AND (LotUnits IS NULL OR LotUnits >= 1)),
    CHECK ((UnitPrice IS NULL OR UnitPrice >= 0) AND (LotPrice IS NULL OR LotPrice >= 0)),
    CHECK ((SellingMethod=N'regular' AND UnitPrice IS NOT NULL) OR (SellingMethod=N'whole_lot' AND LotPrice IS NOT NULL AND LotUnits IS NOT NULL))
);

CREATE TABLE Carts (
    CartID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NOT NULL UNIQUE REFERENCES Users(UserID),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE CartItems (
    CartItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
    CartID BIGINT NOT NULL REFERENCES Carts(CartID),
    ListingID BIGINT NOT NULL REFERENCES Listings(ListingID),
    Quantity INT NOT NULL DEFAULT 1,
    AddedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UNIQUE (CartID, ListingID),
    CHECK (Quantity >= 1)
);

CREATE TABLE Favorites (
    FavoriteID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NOT NULL REFERENCES Users(UserID),
    ListingID BIGINT NOT NULL REFERENCES Listings(ListingID),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UNIQUE (UserID,ListingID)
);

CREATE TABLE Orders (
    OrderID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderNumber NVARCHAR(40) NOT NULL UNIQUE,
    BuyerID BIGINT NULL REFERENCES Users(UserID),
    GuestEmail NVARCHAR(255) NULL,
    ShippingName NVARCHAR(150) NOT NULL,
    ShippingPhone NVARCHAR(30) NULL,
    ShippingCountry NVARCHAR(100) NOT NULL,
    ShippingCity NVARCHAR(100) NOT NULL,
    ShippingAddress NVARCHAR(500) NOT NULL,
    Subtotal DECIMAL(12,2) NOT NULL,
    ServiceFee DECIMAL(12,2) NOT NULL DEFAULT 0,
    ShippingFee DECIMAL(12,2) NOT NULL DEFAULT 0,
    GrandTotal DECIMAL(12,2) NOT NULL,
    OrderStatus NVARCHAR(25) NOT NULL DEFAULT N'pending',
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (Subtotal >= 0 AND ServiceFee >= 0 AND ShippingFee >= 0 AND GrandTotal >= 0),
    CHECK (BuyerID IS NOT NULL OR GuestEmail IS NOT NULL)
);

CREATE TABLE OrderItems (
    OrderItemID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID BIGINT NOT NULL REFERENCES Orders(OrderID),
    ListingID BIGINT NOT NULL REFERENCES Listings(ListingID),
    SellerID BIGINT NOT NULL REFERENCES SellerProfiles(SellerID),
    ProductNameSnapshot NVARCHAR(200) NOT NULL,
    SellingMethodSnapshot NVARCHAR(20) NOT NULL,
    Quantity INT NOT NULL,
    UnitsPerLot INT NULL,
    UnitPrice DECIMAL(12,2) NOT NULL,
    LineTotal DECIMAL(12,2) NOT NULL,
    CHECK (Quantity > 0),
    CHECK (UnitPrice >= 0 AND LineTotal >= 0)
);

CREATE TABLE InventoryMovements (
    MovementID BIGINT IDENTITY(1,1) PRIMARY KEY,
    InventoryID BIGINT NOT NULL REFERENCES Inventory(InventoryID),
    MovementType NVARCHAR(25) NOT NULL,
    QuantityChange INT NOT NULL,
    Reason NVARCHAR(250) NULL,
    ReferenceOrderID BIGINT NULL REFERENCES Orders(OrderID),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (QuantityChange <> 0)
);

CREATE TABLE SubscriptionPlans (
    PlanID INT IDENTITY(1,1) PRIMARY KEY,
    PlanCode NVARCHAR(30) NOT NULL UNIQUE,
    PlanName NVARCHAR(100) NOT NULL,
    DurationMonths INT NOT NULL,
    Price DECIMAL(12,2) NOT NULL,
    Currency CHAR(3) NOT NULL DEFAULT 'JOD',
    IsActive BIT NOT NULL DEFAULT 1,
    CHECK (DurationMonths > 0 AND Price >= 0)
);

CREATE TABLE PlanFeatures (
    FeatureID INT IDENTITY(1,1) PRIMARY KEY,
    FeatureName NVARCHAR(200) NOT NULL UNIQUE
);

CREATE TABLE SubscriptionPlanFeatures (
    PlanID INT NOT NULL REFERENCES SubscriptionPlans(PlanID),
    FeatureID INT NOT NULL REFERENCES PlanFeatures(FeatureID),
    CONSTRAINT PK_SubscriptionPlanFeatures PRIMARY KEY (PlanID, FeatureID)
);

CREATE TABLE Subscriptions (
    SubscriptionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SellerID BIGINT NOT NULL REFERENCES SellerProfiles(SellerID),
    PlanID INT NOT NULL REFERENCES SubscriptionPlans(PlanID),
    Status NVARCHAR(25) NOT NULL DEFAULT N'scheduled',
    StartAt DATETIME2 NOT NULL,
    EndAt DATETIME2 NOT NULL,
    PricePaid DECIMAL(12,2) NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (EndAt > StartAt),
    CHECK (PricePaid >= 0),
    CHECK (Status IN (N'scheduled',N'active',N'expired',N'cancelled'))
);

CREATE TABLE Payments (
    PaymentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID BIGINT NULL REFERENCES Orders(OrderID),
    SubscriptionID BIGINT NULL REFERENCES Subscriptions(SubscriptionID),
    UserID BIGINT NULL REFERENCES Users(UserID),
    Amount DECIMAL(12,2) NOT NULL,
    Currency CHAR(3) NOT NULL DEFAULT 'JOD',
    PaymentMethod NVARCHAR(40) NOT NULL,
    PaymentStatus NVARCHAR(25) NOT NULL DEFAULT N'pending',
    ProviderReference NVARCHAR(180) NULL,
    PaidAt DATETIME2 NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK ((CASE WHEN OrderID IS NULL THEN 0 ELSE 1 END) + (CASE WHEN SubscriptionID IS NULL THEN 0 ELSE 1 END) = 1),
    CHECK (Amount >= 0)
);

CREATE TABLE Shipments (
    ShipmentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderID BIGINT NOT NULL REFERENCES Orders(OrderID),
    SellerID BIGINT NULL REFERENCES SellerProfiles(SellerID),
    TrackingNumber NVARCHAR(100) NULL,
    Carrier NVARCHAR(100) NULL,
    ShipmentStatus NVARCHAR(30) NOT NULL DEFAULT N'processing',
    ShippedAt DATETIME2 NULL,
    DeliveredAt DATETIME2 NULL
);

CREATE TABLE ShipmentEvents (
    EventID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ShipmentID BIGINT NOT NULL REFERENCES Shipments(ShipmentID),
    Status NVARCHAR(30) NOT NULL,
    EventDescription NVARCHAR(400) NULL,
    EventLocation NVARCHAR(180) NULL,
    OccurredAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE Reviews (
    ReviewID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OrderItemID BIGINT NOT NULL UNIQUE REFERENCES OrderItems(OrderItemID),
    ReviewerID BIGINT NOT NULL REFERENCES Users(UserID),
    Rating TINYINT NOT NULL,
    Comment NVARCHAR(2000) NULL,
    ApprovalStatus NVARCHAR(20) NOT NULL DEFAULT N'pending',
    ReviewedByUserID BIGINT NULL REFERENCES Users(UserID),
    ReviewedAt DATETIME2 NULL,
    RejectionReason NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (Rating BETWEEN 1 AND 5),
    CHECK (ApprovalStatus IN (N'pending',N'approved',N'rejected'))
);

CREATE TABLE AdvisorAnalyses (
    AnalysisID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SellerID BIGINT NOT NULL REFERENCES SellerProfiles(SellerID),
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NULL REFERENCES Categories(CategoryID),
    ProductImageUrl NVARCHAR(1000) NULL,
    PurchaseQuantity INT NULL,
    PurchaseUnitCost DECIMAL(12,2) NULL,
    ExpectedSellingPrice DECIMAL(12,2) NULL,
    StoreLocation NVARCHAR(400) NULL,
    BusinessCategory NVARCHAR(60) NULL,
    StoreType NVARCHAR(40) NULL,
    TargetCustomers NVARCHAR(60) NULL,
    VisitorsPerDay INT NULL,
    Recommendation NVARCHAR(30) NULL,
    RiskScore DECIMAL(5,2) NULL,
    AnalysisJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (PurchaseQuantity IS NULL OR PurchaseQuantity >= 0),
    CHECK (RiskScore IS NULL OR RiskScore BETWEEN 0 AND 100),
    CHECK (AnalysisJson IS NULL OR ISJSON(AnalysisJson) = 1)
);

CREATE TABLE RecommendationAnalyses (
    RecommendationID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SellerID BIGINT NOT NULL REFERENCES SellerProfiles(SellerID),
    InventoryProductID BIGINT NULL REFERENCES Products(ProductID),
    ProductName NVARCHAR(200) NOT NULL,
    ProductImageUrl NVARCHAR(1000) NULL,
    QuantityOnHand INT NULL,
    SalesPerWeek DECIMAL(12,2) NULL,
    SuggestedAction NVARCHAR(100) NULL,
    SuggestedDiscountPct DECIMAL(5,2) NULL,
    ForecastJson NVARCHAR(MAX) NULL,
    AnalysisJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (QuantityOnHand IS NULL OR QuantityOnHand >= 0),
    CHECK (SuggestedDiscountPct IS NULL OR SuggestedDiscountPct BETWEEN 0 AND 100),
    CHECK (ForecastJson IS NULL OR ISJSON(ForecastJson) = 1),
    CHECK (AnalysisJson IS NULL OR ISJSON(AnalysisJson) = 1)
);

CREATE TABLE Notifications (
    NotificationID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NOT NULL REFERENCES Users(UserID),
    Title NVARCHAR(180) NOT NULL,
    Body NVARCHAR(1000) NOT NULL,
    NotificationType NVARCHAR(40) NULL,
    IsRead BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE SupportTickets (
    TicketID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NULL REFERENCES Users(UserID),
    GuestEmail NVARCHAR(255) NULL,
    Subject NVARCHAR(200) NOT NULL,
    Message NVARCHAR(MAX) NOT NULL,
    TicketStatus NVARCHAR(20) NOT NULL DEFAULT N'open',
    AssignedAdminID BIGINT NULL REFERENCES Users(UserID),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (UserID IS NOT NULL OR GuestEmail IS NOT NULL)
);

CREATE TABLE SiteSettings (
    SettingKey NVARCHAR(100) NOT NULL PRIMARY KEY,
    SettingValue NVARCHAR(MAX) NULL,
    UpdatedByUserID BIGINT NULL REFERENCES Users(UserID),
    UpdatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE AuditLogs (
    AuditID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ActorUserID BIGINT NULL REFERENCES Users(UserID),
    ActionName NVARCHAR(100) NOT NULL,
    EntityName NVARCHAR(100) NOT NULL,
    EntityID NVARCHAR(80) NULL,
    DetailsJson NVARCHAR(MAX) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (DetailsJson IS NULL OR ISJSON(DetailsJson) = 1)
);

CREATE TABLE SiteFeedback (
    FeedbackID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID BIGINT NULL REFERENCES Users(UserID),
    SourceType NVARCHAR(30) NOT NULL,
    OrderID BIGINT NULL REFERENCES Orders(OrderID),
    DisplayName NVARCHAR(150) NULL,
    ContactEmail NVARCHAR(255) NULL,
    Category NVARCHAR(30) NULL,
    Rating TINYINT NULL,
    Message NVARCHAR(2000) NOT NULL,
    ApprovalStatus NVARCHAR(20) NOT NULL DEFAULT N'pending',
    SubmittedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    ReviewedByUserID BIGINT NULL REFERENCES Users(UserID),
    ReviewedAt DATETIME2 NULL,
    RejectionReason NVARCHAR(1000) NULL,
    CHECK (Rating IS NULL OR Rating BETWEEN 1 AND 5),
    CHECK (ApprovalStatus IN (N'pending',N'approved',N'rejected'))
);

CREATE TABLE ModerationActions (
    ActionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ModeratorUserID BIGINT NOT NULL REFERENCES Users(UserID),
    ProductID BIGINT NULL REFERENCES Products(ProductID),
    ReviewID BIGINT NULL REFERENCES Reviews(ReviewID),
    FeedbackID BIGINT NULL REFERENCES SiteFeedback(FeedbackID),
    ActionType NVARCHAR(20) NOT NULL,
    Reason NVARCHAR(1000) NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (
      (CASE WHEN ProductID IS NULL THEN 0 ELSE 1 END) +
      (CASE WHEN ReviewID IS NULL THEN 0 ELSE 1 END) +
      (CASE WHEN FeedbackID IS NULL THEN 0 ELSE 1 END) = 1),
    CHECK (ActionType IN (N'approve',N'reject',N'reopen'))
);

CREATE TABLE UserPreferences (
    UserID BIGINT NOT NULL PRIMARY KEY REFERENCES Users(UserID),
    OrderNotifications BIT NOT NULL DEFAULT 1,
    ShippingNotifications BIT NOT NULL DEFAULT 1,
    MarketingNotifications BIT NOT NULL DEFAULT 0
);

-- Useful indexes and public-approved views; these are not additional tables.
CREATE INDEX IX_Products_Seller_Approval ON Products(SellerID,ApprovalStatus);
CREATE INDEX IX_Products_Category ON Products(CategoryID);
CREATE INDEX IX_Listings_Product_Status ON Listings(ProductID,Status);
CREATE INDEX IX_Orders_Buyer_Date ON Orders(BuyerID,CreatedAt DESC);
CREATE INDEX IX_OrderItems_Seller ON OrderItems(SellerID);
CREATE INDEX IX_SiteFeedback_Moderation ON SiteFeedback(ApprovalStatus,SubmittedAt DESC);
CREATE INDEX IX_Reviews_Moderation ON Reviews(ApprovalStatus,CreatedAt DESC);
CREATE INDEX IX_Notifications_User_Read ON Notifications(UserID,IsRead,CreatedAt DESC);
CREATE UNIQUE INDEX UX_ProductImages_OnePrimary ON ProductImages(ProductID) WHERE IsPrimary = 1;
CREATE UNIQUE INDEX UX_Addresses_OneDefault ON Addresses(UserID) WHERE IsDefault = 1;
GO
CREATE VIEW vw_PublicListings
AS
SELECT l.*
FROM Listings AS l
JOIN Products AS p ON p.ProductID = l.ProductID
WHERE l.Status = N'active' AND p.ApprovalStatus = N'approved' AND p.Status = N'active';
GO
CREATE VIEW vw_HomeFeedback
AS
SELECT FeedbackID, UserID, DisplayName, Category, Rating, Message, SubmittedAt
FROM SiteFeedback
WHERE ApprovalStatus = N'approved';
GO
/* IMPORTANT:
  - Restrict direct table access; use vw_PublicListings and vw_HomeFeedback for public-facing reads.
  - API must authorize admin moderation and ownership, validate reviewer/order relation,
    use transactions to reserve inventory and prevent double-selling, and secure payments.
  - This script is intended for a fresh DB. Run it once, not over an existing populated schema.
*/

select * from Carts
select * from Orders
select * from Favorites


-- StockMindDB: simple INSERT INTO ... VALUES syntax for demo data across all 32 tables.
-- These are fictional demo records, not actual customer data or real payments.
-- Run AFTER CREATE TABLE has completed, using SQL Server Management Studio.
-- No DROP TABLE / DELETE. Multiple rows are grouped under VALUES.
-- Foreign keys use SELECT to find the correct ID even if existing IDs differ.
-- One-time seed; any error rolls the whole batch back.
USE StockMindDB;
SET XACT_ABORT ON;
BEGIN TRY
BEGIN TRANSACTION;

IF EXISTS (SELECT 1 FROM Users WHERE Email = N'stockmind.demo01@example.com')
    THROW 51000, 'StockMind demo records already exist; seed was not run again.', 1;


IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = N'admin')
    INSERT INTO Roles (RoleName) VALUES (N'admin');


IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = N'seller')
    INSERT INTO Roles (RoleName) VALUES (N'seller');


IF NOT EXISTS (SELECT 1 FROM Roles WHERE RoleName = N'buyer')
    INSERT INTO Roles (RoleName) VALUES (N'buyer');


INSERT INTO Users (RoleID, FullName, Email, PasswordHash, Phone, EmailVerified)
VALUES
((SELECT RoleID FROM Roles WHERE RoleName = N'admin'), N'Omar Khaled', N'stockmind.demo01@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000001', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'seller'), N'Lina Ahmad', N'stockmind.demo02@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000002', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'seller'), N'Yazan Saleh', N'stockmind.demo03@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000003', 1),
((SELECT RoleID FROM Roles WHERE RoleName = N'seller'), N'Maya Nasser', N'stockmind.demo04@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000004', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'seller'), N'Tariq Hamdan', N'stockmind.demo05@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000005', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Rana Hussein', N'stockmind.demo06@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000006', 1),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Kareem Ali', N'stockmind.demo07@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000007', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Dina Faris', N'stockmind.demo08@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000008', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Sami Qasem', N'stockmind.demo09@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000009', 1),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Noor Ibrahim', N'stockmind.demo10@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000010', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Basil Adel', N'stockmind.demo11@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000011', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Salma Taha', N'stockmind.demo12@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000012', 1),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Huda Rami', N'stockmind.demo13@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000013', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Fadi Yousef', N'stockmind.demo14@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000014', 0),
((SELECT RoleID FROM Roles WHERE RoleName = N'buyer'), N'Ruba Mansour', N'stockmind.demo15@example.com', N'DEMO_ACCOUNT_NO_LOGIN_HASH', N'0793000015', 1);


INSERT INTO Addresses (UserID, RecipientName, Phone, Country, City, StreetAddress, IsDefault)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), N'Rana Hussein', N'0793000006', N'Jordan', N'Amman', N'Demo Street 1, Building 11', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), N'Kareem Ali', N'0793000007', N'Jordan', N'Irbid', N'Demo Street 2, Building 12', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), N'Dina Faris', N'0793000008', N'Jordan', N'Amman', N'Demo Street 3, Building 13', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), N'Sami Qasem', N'0793000009', N'Jordan', N'Irbid', N'Demo Street 4, Building 14', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), N'Noor Ibrahim', N'0793000010', N'Jordan', N'Amman', N'Demo Street 5, Building 15', 1);


INSERT INTO SellerProfiles (UserID, StoreName, Description, Country, City, BusinessCategory, StoreType, VerificationStatus, AverageVisitorsPerDay)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo02@example.com'), N'Amman Tech Corner', N'Demo storefront for Amman Tech Corner', N'Jordan', N'Amman', N'Electronics', N'Online', N'approved', 52),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo03@example.com'), N'Green Home Store', N'Demo storefront for Green Home Store', N'Jordan', N'Amman', N'Home', N'Online', N'approved', 63),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo04@example.com'), N'City Fashion Hub', N'Demo storefront for City Fashion Hub', N'Jordan', N'Amman', N'Fashion', N'Online', N'approved', 74),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo05@example.com'), N'Smart Gadgets JO', N'Demo storefront for Smart Gadgets JO', N'Jordan', N'Amman', N'Electronics', N'Online', N'approved', 85);


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Electronics')
    INSERT INTO Categories (CategoryName) VALUES (N'Electronics');


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Home & Kitchen')
    INSERT INTO Categories (CategoryName) VALUES (N'Home & Kitchen');


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Clothing')
    INSERT INTO Categories (CategoryName) VALUES (N'Clothing');


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Accessories')
    INSERT INTO Categories (CategoryName) VALUES (N'Accessories');


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Groceries')
    INSERT INTO Categories (CategoryName) VALUES (N'Groceries');


IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Office Supplies')
    INSERT INTO Categories (CategoryName) VALUES (N'Office Supplies');


INSERT INTO Products (SellerID, CategoryID, ProductName, Description, ProductCondition, ApprovalStatus, SKU, Status)
VALUES
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), N'Wireless Mouse', N'Demo product: Wireless Mouse', N'New', N'approved', N'DEMO-SKU-001', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), N'USB-C Cable 1m', N'Demo product: USB-C Cable 1m', N'New', N'approved', N'DEMO-SKU-002', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), N'Bluetooth Speaker', N'Demo product: Bluetooth Speaker', N'New', N'approved', N'DEMO-SKU-003', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Home & Kitchen'), N'LED Desk Lamp', N'Demo product: LED Desk Lamp', N'New', N'approved', N'DEMO-SKU-004', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Home & Kitchen'), N'Ceramic Mug', N'Demo product: Ceramic Mug', N'New', N'approved', N'DEMO-SKU-005', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Home & Kitchen'), N'Storage Box', N'Demo product: Storage Box', N'New', N'approved', N'DEMO-SKU-006', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Clothing'), N'Cotton T-Shirt', N'Demo product: Cotton T-Shirt', N'New', N'approved', N'DEMO-SKU-007', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Clothing'), N'Denim Jacket', N'Demo product: Denim Jacket', N'New', N'approved', N'DEMO-SKU-008', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Accessories'), N'Canvas Tote Bag', N'Demo product: Canvas Tote Bag', N'New', N'approved', N'DEMO-SKU-009', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Smart Gadgets JO'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Accessories'), N'Phone Stand', N'Demo product: Phone Stand', N'New', N'approved', N'DEMO-SKU-010', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Smart Gadgets JO'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), N'Power Bank 10000mAh', N'Demo product: Power Bank 10000mAh', N'New', N'approved', N'DEMO-SKU-011', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Smart Gadgets JO'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Office Supplies'), N'Notebook A5', N'Demo product: Notebook A5', N'New', N'approved', N'DEMO-SKU-012', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Groceries'), N'Olive Oil 500ml', N'Demo product: Olive Oil 500ml', N'New', N'approved', N'DEMO-SKU-013', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Accessories'), N'Reusable Water Bottle', N'Demo product: Reusable Water Bottle', N'New', N'approved', N'DEMO-SKU-014', N'active'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), N'Keyboard', N'Demo product: Keyboard', N'New', N'approved', N'DEMO-SKU-015', N'active');


INSERT INTO ProductImages (ProductID, ImageUrl, IsPrimary, SortOrder)
VALUES
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001'), N'https://example.com/demo/product-001.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002'), N'https://example.com/demo/product-002.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003'), N'https://example.com/demo/product-003.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004'), N'https://example.com/demo/product-004.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005'), N'https://example.com/demo/product-005.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-006'), N'https://example.com/demo/product-006.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-007'), N'https://example.com/demo/product-007.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-008'), N'https://example.com/demo/product-008.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-009'), N'https://example.com/demo/product-009.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-010'), N'https://example.com/demo/product-010.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-011'), N'https://example.com/demo/product-011.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-012'), N'https://example.com/demo/product-012.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-013'), N'https://example.com/demo/product-013.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-014'), N'https://example.com/demo/product-014.jpg', 1, 0),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-015'), N'https://example.com/demo/product-015.jpg', 1, 0);


INSERT INTO Inventory (ProductID, AvailableQuantity, ReservedQuantity, ReorderLevel, UnitCost)
VALUES
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001'), 12, 0, 5, 5.53),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002'), 14, 0, 5, 2.11),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003'), 16, 0, 5, 14.3),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004'), 18, 0, 5, 9.43),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005'), 20, 0, 5, 3.25),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-006'), 22, 0, 5, 5.04),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-007'), 24, 0, 5, 7.8),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-008'), 26, 0, 5, 22.75),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-009'), 28, 0, 5, 4.23),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-010'), 30, 0, 5, 3.09),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-011'), 32, 0, 5, 12.93),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-012'), 34, 0, 5, 1.46),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-013'), 36, 0, 5, 6.17),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-014'), 38, 0, 5, 6.5),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-015'), 40, 0, 5, 10.4);


INSERT INTO Listings (ProductID, SellingMethod, UnitPrice, MinOrderQuantity, ListingQuantity, Status, PublishedAt)
VALUES
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001'), N'regular', 8.5, 1, 12, N'active', DATEADD(DAY,-1,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002'), N'regular', 3.25, 1, 14, N'active', DATEADD(DAY,-2,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003'), N'regular', 22.0, 1, 16, N'active', DATEADD(DAY,-3,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004'), N'regular', 14.5, 1, 18, N'active', DATEADD(DAY,-4,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005'), N'regular', 5.0, 1, 20, N'active', DATEADD(DAY,-5,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-006'), N'regular', 7.75, 1, 22, N'active', DATEADD(DAY,-6,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-007'), N'regular', 12.0, 1, 24, N'active', DATEADD(DAY,-7,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-008'), N'regular', 35.0, 1, 26, N'active', DATEADD(DAY,-8,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-009'), N'regular', 6.5, 1, 28, N'active', DATEADD(DAY,-9,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-010'), N'regular', 4.75, 1, 30, N'active', DATEADD(DAY,-10,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-011'), N'regular', 19.9, 1, 32, N'active', DATEADD(DAY,-11,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-012'), N'regular', 2.25, 1, 34, N'active', DATEADD(DAY,-12,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-013'), N'regular', 9.5, 1, 36, N'active', DATEADD(DAY,-13,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-014'), N'regular', 10.0, 1, 38, N'active', DATEADD(DAY,-14,SYSUTCDATETIME())),
((SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-015'), N'regular', 16.0, 1, 40, N'active', DATEADD(DAY,-15,SYSUTCDATETIME()));


INSERT INTO Carts (UserID)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com')),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com')),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com')),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com')),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'));


INSERT INTO CartItems (CartID, ListingID, Quantity)
VALUES
((SELECT CartID FROM Carts WHERE UserID = (SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com')), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001') ORDER BY ListingID), 2),
((SELECT CartID FROM Carts WHERE UserID = (SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com')), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002') ORDER BY ListingID), 3),
((SELECT CartID FROM Carts WHERE UserID = (SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com')), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003') ORDER BY ListingID), 1),
((SELECT CartID FROM Carts WHERE UserID = (SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com')), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004') ORDER BY ListingID), 2),
((SELECT CartID FROM Carts WHERE UserID = (SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com')), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005') ORDER BY ListingID), 3);


INSERT INTO Favorites (UserID, ListingID)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-006') ORDER BY ListingID)),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-007') ORDER BY ListingID)),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-008') ORDER BY ListingID)),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-009') ORDER BY ListingID)),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-010') ORDER BY ListingID));


INSERT INTO Orders (OrderNumber, BuyerID, ShippingName, ShippingCountry, ShippingCity, ShippingAddress, Subtotal, ServiceFee, ShippingFee, GrandTotal, OrderStatus)
VALUES
(N'DEMO-ORD-0001', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), N'Rana Hussein', N'Jordan', N'Amman', N'Demo Street 1, Building 22', 17.0, 0, 2.5, 19.5, N'delivered'),
(N'DEMO-ORD-0002', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), N'Kareem Ali', N'Jordan', N'Amman', N'Demo Street 2, Building 22', 3.25, 0, 2.5, 5.75, N'delivered'),
(N'DEMO-ORD-0003', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), N'Dina Faris', N'Jordan', N'Amman', N'Demo Street 3, Building 22', 44.0, 0, 2.5, 46.5, N'delivered'),
(N'DEMO-ORD-0004', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), N'Sami Qasem', N'Jordan', N'Amman', N'Demo Street 4, Building 22', 14.5, 0, 2.5, 17.0, N'delivered'),
(N'DEMO-ORD-0005', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), N'Noor Ibrahim', N'Jordan', N'Amman', N'Demo Street 5, Building 22', 10.0, 0, 2.5, 12.5, N'processing'),
(N'DEMO-ORD-0006', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo11@example.com'), N'Basil Adel', N'Jordan', N'Amman', N'Demo Street 6, Building 22', 7.75, 0, 2.5, 10.25, N'processing'),
(N'DEMO-ORD-0007', (SELECT UserID FROM Users WHERE Email = N'stockmind.demo12@example.com'), N'Salma Taha', N'Jordan', N'Amman', N'Demo Street 7, Building 22', 24.0, 0, 2.5, 26.5, N'processing');


INSERT INTO OrderItems (OrderID, ListingID, SellerID, ProductNameSnapshot, SellingMethodSnapshot, Quantity, UnitPrice, LineTotal)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'Wireless Mouse', N'regular', 2, 8.5, 17.0),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'USB-C Cable 1m', N'regular', 1, 3.25, 3.25),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'Bluetooth Speaker', N'regular', 2, 22.0, 44.0),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), N'LED Desk Lamp', N'regular', 1, 14.5, 14.5),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0005'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), N'Ceramic Mug', N'regular', 2, 5.0, 10.0),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0006'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-006') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), N'Storage Box', N'regular', 1, 7.75, 7.75),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0007'), (SELECT TOP 1 ListingID FROM Listings WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-007') ORDER BY ListingID), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), N'Cotton T-Shirt', N'regular', 2, 12.0, 24.0);


INSERT INTO InventoryMovements (InventoryID, MovementType, QuantityChange, Reason, ReferenceOrderID)
VALUES
((SELECT InventoryID FROM Inventory WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001')), N'sale', -2, N'Demo order fulfillment', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001')),
((SELECT InventoryID FROM Inventory WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002')), N'sale', -1, N'Demo order fulfillment', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002')),
((SELECT InventoryID FROM Inventory WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003')), N'sale', -2, N'Demo order fulfillment', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003')),
((SELECT InventoryID FROM Inventory WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004')), N'sale', -1, N'Demo order fulfillment', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004')),
((SELECT InventoryID FROM Inventory WHERE ProductID = (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-005')), N'sale', -2, N'Demo order fulfillment', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0005'));


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = N'BASIC')
    INSERT INTO SubscriptionPlans (PlanCode,PlanName,DurationMonths,Price) VALUES (N'BASIC',N'Basic',1,0);


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlans WHERE PlanCode = N'PRO')
    INSERT INTO SubscriptionPlans (PlanCode,PlanName,DurationMonths,Price) VALUES (N'PRO',N'Pro',1,15);


IF NOT EXISTS (SELECT 1 FROM PlanFeatures WHERE FeatureName = N'Product listings')
    INSERT INTO PlanFeatures (FeatureName) VALUES (N'Product listings');


IF NOT EXISTS (SELECT 1 FROM PlanFeatures WHERE FeatureName = N'AI recommendations')
    INSERT INTO PlanFeatures (FeatureName) VALUES (N'AI recommendations');


IF NOT EXISTS (SELECT 1 FROM PlanFeatures WHERE FeatureName = N'Sales reports')
    INSERT INTO PlanFeatures (FeatureName) VALUES (N'Sales reports');


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlanFeatures WHERE PlanID = (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'BASIC') AND FeatureID = (SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Product listings'))
    INSERT INTO SubscriptionPlanFeatures (PlanID,FeatureID) VALUES ((SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'BASIC'),(SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Product listings'));


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlanFeatures WHERE PlanID = (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO') AND FeatureID = (SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Product listings'))
    INSERT INTO SubscriptionPlanFeatures (PlanID,FeatureID) VALUES ((SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO'),(SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Product listings'));


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlanFeatures WHERE PlanID = (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO') AND FeatureID = (SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'AI recommendations'))
    INSERT INTO SubscriptionPlanFeatures (PlanID,FeatureID) VALUES ((SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO'),(SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'AI recommendations'));


IF NOT EXISTS (SELECT 1 FROM SubscriptionPlanFeatures WHERE PlanID = (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO') AND FeatureID = (SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Sales reports'))
    INSERT INTO SubscriptionPlanFeatures (PlanID,FeatureID) VALUES ((SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO'),(SELECT FeatureID FROM PlanFeatures WHERE FeatureName = N'Sales reports'));


INSERT INTO Subscriptions (SellerID, PlanID, Status, StartAt, EndAt, PricePaid)
VALUES
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'BASIC'), N'active', DATEADD(DAY,-5,SYSUTCDATETIME()), DATEADD(DAY,25,SYSUTCDATETIME()), 0),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO'), N'active', DATEADD(DAY,-5,SYSUTCDATETIME()), DATEADD(DAY,25,SYSUTCDATETIME()), 15),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'BASIC'), N'active', DATEADD(DAY,-5,SYSUTCDATETIME()), DATEADD(DAY,25,SYSUTCDATETIME()), 0),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Smart Gadgets JO'), (SELECT PlanID FROM SubscriptionPlans WHERE PlanCode = N'PRO'), N'active', DATEADD(DAY,-5,SYSUTCDATETIME()), DATEADD(DAY,25,SYSUTCDATETIME()), 15);


INSERT INTO Payments (OrderID, UserID, Amount, Currency, PaymentMethod, PaymentStatus, ProviderReference, PaidAt)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), 19.5, N'JOD', N'cash_on_delivery', N'paid', N'DEMO-PAY-0001', SYSUTCDATETIME()),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), 5.75, N'JOD', N'cash_on_delivery', N'paid', N'DEMO-PAY-0002', SYSUTCDATETIME()),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), 46.5, N'JOD', N'cash_on_delivery', N'paid', N'DEMO-PAY-0003', SYSUTCDATETIME()),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), 17.0, N'JOD', N'cash_on_delivery', N'paid', N'DEMO-PAY-0004', SYSUTCDATETIME()),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0005'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), 12.5, N'JOD', N'cash_on_delivery', N'pending', N'DEMO-PAY-0005', NULL),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0006'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo11@example.com'), 10.25, N'JOD', N'cash_on_delivery', N'pending', N'DEMO-PAY-0006', NULL),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0007'), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo12@example.com'), 26.5, N'JOD', N'cash_on_delivery', N'pending', N'DEMO-PAY-0007', NULL);


INSERT INTO Shipments (OrderID, SellerID, TrackingNumber, Carrier, ShipmentStatus, ShippedAt, DeliveredAt)
VALUES
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001'), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'DEMO-TRACK-0001', N'Demo Logistics', N'delivered', DATEADD(DAY,-3,SYSUTCDATETIME()), DATEADD(DAY,-1,SYSUTCDATETIME())),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002'), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'DEMO-TRACK-0002', N'Demo Logistics', N'delivered', DATEADD(DAY,-3,SYSUTCDATETIME()), DATEADD(DAY,-1,SYSUTCDATETIME())),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003'), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'DEMO-TRACK-0003', N'Demo Logistics', N'delivered', DATEADD(DAY,-3,SYSUTCDATETIME()), DATEADD(DAY,-1,SYSUTCDATETIME())),
((SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004'), (SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), N'DEMO-TRACK-0004', N'Demo Logistics', N'delivered', DATEADD(DAY,-3,SYSUTCDATETIME()), DATEADD(DAY,-1,SYSUTCDATETIME()));


INSERT INTO ShipmentEvents (ShipmentID, Status, EventDescription, EventLocation)
VALUES
((SELECT ShipmentID FROM Shipments WHERE TrackingNumber = N'DEMO-TRACK-0001'), N'delivered', N'Demo delivery completed', N'Amman'),
((SELECT ShipmentID FROM Shipments WHERE TrackingNumber = N'DEMO-TRACK-0002'), N'delivered', N'Demo delivery completed', N'Amman'),
((SELECT ShipmentID FROM Shipments WHERE TrackingNumber = N'DEMO-TRACK-0003'), N'delivered', N'Demo delivery completed', N'Amman'),
((SELECT ShipmentID FROM Shipments WHERE TrackingNumber = N'DEMO-TRACK-0004'), N'delivered', N'Demo delivery completed', N'Amman');


INSERT INTO Reviews (OrderItemID, ReviewerID, Rating, Comment, ApprovalStatus)
VALUES
((SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001') ORDER BY OrderItemID), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), 5, N'Good experience with demo order 1', N'approved'),
((SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002') ORDER BY OrderItemID), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), 4, N'Good experience with demo order 2', N'approved'),
((SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003') ORDER BY OrderItemID), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), 5, N'Good experience with demo order 3', N'approved'),
((SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004') ORDER BY OrderItemID), (SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), 4, N'Good experience with demo order 4', N'approved');


INSERT INTO AdvisorAnalyses (SellerID, ProductName, CategoryID, PurchaseQuantity, PurchaseUnitCost, ExpectedSellingPrice, Recommendation, RiskScore, AnalysisJson)
VALUES
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), N'Wireless Mouse', (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), 20, 5, 10, N'Buy', 32, N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), N'USB-C Cable 1m', (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), 20, 5, 10, N'Review', 39, N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'City Fashion Hub'), N'Bluetooth Speaker', (SELECT CategoryID FROM Categories WHERE CategoryName = N'Electronics'), 20, 5, 10, N'Buy', 46, N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Smart Gadgets JO'), N'LED Desk Lamp', (SELECT CategoryID FROM Categories WHERE CategoryName = N'Home & Kitchen'), 20, 5, 10, N'Review', 53, N'{"source":"demo"}');


INSERT INTO RecommendationAnalyses (SellerID, InventoryProductID, ProductName, QuantityOnHand, SalesPerWeek, SuggestedAction, SuggestedDiscountPct, ForecastJson, AnalysisJson)
VALUES
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-001'), N'Wireless Mouse', 11, 3, N'Promote product', 5, N'{"trend":"stable"}', N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-002'), N'USB-C Cable 1m', 12, 4, N'Promote product', 5, N'{"trend":"stable"}', N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Amman Tech Corner'), (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-003'), N'Bluetooth Speaker', 13, 5, N'Promote product', 5, N'{"trend":"stable"}', N'{"source":"demo"}'),
((SELECT SellerID FROM SellerProfiles WHERE StoreName = N'Green Home Store'), (SELECT ProductID FROM Products WHERE SKU = N'DEMO-SKU-004'), N'LED Desk Lamp', 14, 6, N'Promote product', 5, N'{"trend":"stable"}', N'{"source":"demo"}');


INSERT INTO Notifications (UserID, Title, Body, NotificationType, IsRead)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo02@example.com'), N'Demo notification 1', N'Your StockMind demo update number 1.', N'general', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo03@example.com'), N'Demo notification 2', N'Your StockMind demo update number 2.', N'general', 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo04@example.com'), N'Demo notification 3', N'Your StockMind demo update number 3.', N'general', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo05@example.com'), N'Demo notification 4', N'Your StockMind demo update number 4.', N'general', 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), N'Demo notification 5', N'Your StockMind demo update number 5.', N'general', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), N'Demo notification 6', N'Your StockMind demo update number 6.', N'general', 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), N'Demo notification 7', N'Your StockMind demo update number 7.', N'general', 1),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), N'Demo notification 8', N'Your StockMind demo update number 8.', N'general', 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), N'Demo notification 9', N'Your StockMind demo update number 9.', N'general', 1);


INSERT INTO SupportTickets (UserID, Subject, Message, TicketStatus)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), N'Demo support question 1', N'How can I manage my store order?', N'open'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), N'Demo support question 2', N'How can I manage my store order?', N'open'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), N'Demo support question 3', N'How can I manage my store order?', N'open');


IF NOT EXISTS (SELECT 1 FROM SiteSettings WHERE SettingKey = N'demo.maintenance')
    INSERT INTO SiteSettings (SettingKey,SettingValue) VALUES (N'demo.maintenance',N'false');


IF NOT EXISTS (SELECT 1 FROM SiteSettings WHERE SettingKey = N'demo.currency')
    INSERT INTO SiteSettings (SettingKey,SettingValue) VALUES (N'demo.currency',N'JOD');


IF NOT EXISTS (SELECT 1 FROM SiteSettings WHERE SettingKey = N'demo.support_email')
    INSERT INTO SiteSettings (SettingKey,SettingValue) VALUES (N'demo.support_email',N'support@example.com');


INSERT INTO AuditLogs (ActorUserID, ActionName, EntityName, EntityID, DetailsJson)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), N'demo_seed', N'Products', N'DEMO-SKU-001', N'{"source":"sample"}'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), N'demo_seed', N'Products', N'DEMO-SKU-002', N'{"source":"sample"}'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), N'demo_seed', N'Products', N'DEMO-SKU-003', N'{"source":"sample"}'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), N'demo_seed', N'Products', N'DEMO-SKU-004', N'{"source":"sample"}');


INSERT INTO SiteFeedback (UserID, SourceType, OrderID, DisplayName, Category, Rating, Message, ApprovalStatus)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), N'order', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001'), N'Rana Hussein', N'service', 5, N'Easy demo shopping experience.', N'approved'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), N'order', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002'), N'Kareem Ali', N'service', 4, N'Easy demo shopping experience.', N'approved'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), N'order', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003'), N'Dina Faris', N'service', 5, N'Easy demo shopping experience.', N'approved'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), N'order', (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0004'), N'Sami Qasem', N'service', 4, N'Easy demo shopping experience.', N'approved');


INSERT INTO ModerationActions (ModeratorUserID, ReviewID, ActionType, Reason)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), (SELECT TOP 1 ReviewID FROM Reviews WHERE OrderItemID = (SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0001'))), N'approve', N'Demo sample review approved'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), (SELECT TOP 1 ReviewID FROM Reviews WHERE OrderItemID = (SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0002'))), N'approve', N'Demo sample review approved'),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo01@example.com'), (SELECT TOP 1 ReviewID FROM Reviews WHERE OrderItemID = (SELECT TOP 1 OrderItemID FROM OrderItems WHERE OrderID = (SELECT OrderID FROM Orders WHERE OrderNumber = N'DEMO-ORD-0003'))), N'approve', N'Demo sample review approved');


INSERT INTO UserPreferences (UserID, OrderNotifications, ShippingNotifications, MarketingNotifications)
VALUES
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo06@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo07@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo08@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo09@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo10@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo11@example.com'), 1, 1, 0),
((SELECT UserID FROM Users WHERE Email = N'stockmind.demo12@example.com'), 1, 1, 0);


COMMIT TRANSACTION;
PRINT 'StockMind demo data inserted successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Check how many rows are in each table after the insert.
SELECT t.name AS TableName, SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0,1)
GROUP BY t.name
ORDER BY t.name;

select * from Favorites