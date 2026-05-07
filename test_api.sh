#!/bin/bash
# ============================================================
# BHARATA HERBAL API — Full Test Suite
# Jalankan di Debian: bash test_api.sh
# ============================================================

BASE_URL="http://127.0.0.1:8000/api"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOKEN=""
ORDER_ID=""
REVIEW_ID=""
ADDRESS_ID=""
CART_ITEM_ID=""
PRODUCT_SLUG=""

print_header() { echo -e "\n${CYAN}${BOLD}══════════════════════════════════════${NC}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${CYAN}${BOLD}══════════════════════════════════════${NC}"; }
print_test()   { echo -e "\n${YELLOW}▶ $1${NC}"; }
pass()         { echo -e "  ${GREEN}✓ PASS${NC} — $1"; ((PASS++)); }
fail()         { echo -e "  ${RED}✗ FAIL${NC} — $1"; ((FAIL++)); }
show_json()    { echo "$1" | python3 -m json.tool 2>/dev/null || echo "$1"; }

# Helper: call API dan tampilkan response
call() {
    local METHOD=$1 URL=$2 BODY=$3 AUTH=$4
    local HEADERS=(-H "Accept: application/json" -H "Content-Type: application/json")
    [[ -n "$AUTH" ]] && HEADERS+=(-H "Authorization: Bearer $AUTH")
    if [[ -n "$BODY" ]]; then
        curl -s -X "$METHOD" "$BASE_URL$URL" "${HEADERS[@]}" -d "$BODY"
    else
        curl -s -X "$METHOD" "$BASE_URL$URL" "${HEADERS[@]}"
    fi
}

# ─── Cek server running ──────────────────────────────────────
print_header "PRE-CHECK: Server & DB"
print_test "Cek server Laravel berjalan di :8000"
HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/up)
if [[ "$HEALTH" == "200" ]]; then
    pass "Server aktif (HTTP $HEALTH)"
else
    fail "Server tidak aktif! Jalankan: php artisan serve"
    echo -e "${RED}Jalankan dulu: php artisan serve &${NC}"
    exit 1
fi

# ─── TEST 1: REGISTER ────────────────────────────────────────
print_header "1. AUTH — REGISTER"
TIMESTAMP=$(date +%s)
TEST_EMAIL="test${TIMESTAMP}@bharataherbal.com"
TEST_PHONE="08${TIMESTAMP: -9}"

print_test "POST /api/register — Data valid"
RESP=$(call POST /register "{
  \"name\": \"Test User\",
  \"email\": \"$TEST_EMAIL\",
  \"phone\": \"$TEST_PHONE\",
  \"password\": \"Password123!\",
  \"password_confirmation\": \"Password123!\"
}")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('token',''))" 2>/dev/null)
if [[ "$SUCCESS" == "True" && -n "$TOKEN" ]]; then
    pass "Register berhasil, token diterima"
    echo "  Token: ${TOKEN:0:30}..."
else
    fail "Register gagal"
    show_json "$RESP"
fi

print_test "POST /api/register — Email duplikat"
RESP2=$(call POST /register "{
  \"name\": \"Test\",
  \"email\": \"$TEST_EMAIL\",
  \"phone\": \"$TEST_PHONE\",
  \"password\": \"Password123!\",
  \"password_confirmation\": \"Password123!\"
}")
HTTP_STATUS=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$HTTP_STATUS" == "False" ]]; then
    pass "Email duplikat ditolak dengan benar"
else
    fail "Seharusnya ditolak"
fi

print_test "POST /api/register — Data tidak valid (phone salah)"
RESP3=$(call POST /register '{"name":"X","email":"bad-email","phone":"123","password":"weak","password_confirmation":"weak"}')
SUCCESS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
ERRORS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print('errors' in d)" 2>/dev/null)
if [[ "$SUCCESS3" == "False" && "$ERRORS3" == "True" ]]; then
    pass "Validasi error dikembalikan dengan field errors"
else
    fail "Format error tidak sesuai"
    show_json "$RESP3"
fi

# ─── TEST 2: LOGIN ───────────────────────────────────────────
print_header "2. AUTH — LOGIN"

print_test "POST /api/login — Credentials valid"
RESP=$(call POST /login "{\"email\":\"$TEST_EMAIL\",\"password\":\"Password123!\"}")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('token',''))" 2>/dev/null)
if [[ "$SUCCESS" == "True" && -n "$TOKEN" ]]; then
    pass "Login berhasil"
else
    fail "Login gagal"
    show_json "$RESP"
fi

print_test "POST /api/login — Password salah"
RESP2=$(call POST /login "{\"email\":\"$TEST_EMAIL\",\"password\":\"wrongpass\"}")
MSG=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if [[ "$MSG" == *"salah"* ]]; then
    pass "Password salah ditolak: '$MSG'"
else
    fail "Seharusnya ada pesan error"
    show_json "$RESP2"
fi

# ─── TEST 3: ME ──────────────────────────────────────────────
print_header "3. AUTH — GET ME"

print_test "GET /api/me — Dengan token"
RESP=$(call GET /me "" "$TOKEN")
USER_ID=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('id',''))" 2>/dev/null)
ROLE=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('role',''))" 2>/dev/null)
if [[ -n "$USER_ID" && "$ROLE" == "customer" ]]; then
    pass "GET /me berhasil (id=$USER_ID, role=$ROLE)"
else
    fail "GET /me gagal"
    show_json "$RESP"
fi

print_test "GET /api/me — Tanpa token (harus 401)"
RESP2=$(call GET /me)
MSG=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if [[ "$MSG" == *"Unauthenticated"* ]]; then
    pass "Tanpa token ditolak: '$MSG'"
else
    fail "Seharusnya 401 Unauthenticated"
    show_json "$RESP2"
fi

# ─── TEST 4: PRODUCTS ────────────────────────────────────────
print_header "4. PRODUCTS (PUBLIC)"

print_test "GET /api/products — Default listing"
RESP=$(call GET /products)
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
TOTAL=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('pagination',{}).get('total',0))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    pass "Listing produk OK (total=$TOTAL)"
    PRODUCT_SLUG=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); items=d.get('data',{}).get('data',[]); print(items[0].get('slug','') if items else '')" 2>/dev/null)
else
    fail "Listing produk gagal"
    show_json "$RESP"
fi

print_test "GET /api/products?per_page=3&sort=price_asc"
RESP2=$(call GET "/products?per_page=3&sort=price_asc")
PER_PAGE=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('pagination',{}).get('per_page',0))" 2>/dev/null)
if [[ "$PER_PAGE" == "3" ]]; then
    pass "Pagination & sort berfungsi (per_page=$PER_PAGE)"
else
    fail "Pagination gagal"
    show_json "$RESP2"
fi

print_test "GET /api/products?search=... — Filter search"
RESP3=$(call GET "/products?search=herbal")
SUCCESS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS3" == "True" ]]; then
    COUNT=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('data',{}).get('data',[])))" 2>/dev/null)
    pass "Search berfungsi (ditemukan $COUNT produk)"
else
    fail "Search gagal"
fi

if [[ -n "$PRODUCT_SLUG" ]]; then
    print_test "GET /api/products/$PRODUCT_SLUG — Product detail"
    RESP4=$(call GET "/products/$PRODUCT_SLUG")
    PROD_NAME=$(echo "$RESP4" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('name',''))" 2>/dev/null)
    if [[ -n "$PROD_NAME" ]]; then
        pass "Detail produk OK: '$PROD_NAME'"
    else
        fail "Detail produk gagal"
        show_json "$RESP4"
    fi
fi

print_test "GET /api/products/slug-tidak-ada — Harus 404"
RESP5=$(call GET "/products/produk-tidak-ada-xyz-123")
MSG5=$(echo "$RESP5" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if [[ "$MSG5" == *"tidak ditemukan"* ]]; then
    pass "404 handler berfungsi: '$MSG5'"
else
    fail "Seharusnya 404"
    show_json "$RESP5"
fi

# ─── TEST 5: CATEGORIES ──────────────────────────────────────
print_header "5. CATEGORIES (PUBLIC)"

print_test "GET /api/categories"
RESP=$(call GET /categories)
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
COUNT=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('data',[])))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    pass "Categories OK ($COUNT kategori)"
else
    fail "Categories gagal"
    show_json "$RESP"
fi

# ─── TEST 6: ADDRESSES ───────────────────────────────────────
print_header "6. ADDRESSES (AUTH)"

print_test "GET /api/addresses — Awalnya kosong"
RESP=$(call GET /addresses "" "$TOKEN")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    pass "GET addresses OK"
else
    fail "GET addresses gagal"
    show_json "$RESP"
fi

print_test "POST /api/addresses — Tambah alamat"
RESP2=$(call POST /addresses "{
  \"label\": \"Rumah\",
  \"recipient_name\": \"Test User\",
  \"phone\": \"081234567890\",
  \"street\": \"Jl. Merdeka No. 123\",
  \"city\": \"Jakarta Pusat\",
  \"province\": \"DKI Jakarta\",
  \"postal_code\": \"10110\",
  \"is_default\": true
}" "$TOKEN")
SUCCESS2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
ADDRESS_ID=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('id',''))" 2>/dev/null)
if [[ "$SUCCESS2" == "True" && -n "$ADDRESS_ID" ]]; then
    pass "Tambah alamat berhasil (id=$ADDRESS_ID)"
else
    fail "Tambah alamat gagal"
    show_json "$RESP2"
fi

print_test "PATCH /api/addresses/$ADDRESS_ID/default — Set default"
if [[ -n "$ADDRESS_ID" ]]; then
    RESP3=$(call PATCH "/addresses/$ADDRESS_ID/default" "" "$TOKEN")
    SUCCESS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
    if [[ "$SUCCESS3" == "True" ]]; then
        pass "Set default berhasil"
    else
        fail "Set default gagal"
        show_json "$RESP3"
    fi
fi

# ─── TEST 7: CART ────────────────────────────────────────────
print_header "7. CART (AUTH)"

# Ambil product_id dari listing
PRODUCT_ID=$(call GET /products | python3 -c "import sys,json; d=json.load(sys.stdin); items=d.get('data',{}).get('data',[]); print(items[0].get('id','') if items else '')" 2>/dev/null)

print_test "GET /api/cart — Cart awal"
RESP=$(call GET /cart "" "$TOKEN")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    pass "GET cart OK"
else
    fail "GET cart gagal"
    show_json "$RESP"
fi

if [[ -n "$PRODUCT_ID" ]]; then
    print_test "POST /api/cart — Tambah produk (id=$PRODUCT_ID)"
    RESP2=$(call POST /cart "{\"product_id\": $PRODUCT_ID, \"quantity\": 2}" "$TOKEN")
    SUCCESS2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
    ITEM_COUNT=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('data',{}).get('items',[])))" 2>/dev/null)
    CART_ITEM_ID=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); items=d.get('data',{}).get('items',[]); print(items[0].get('id','') if items else '')" 2>/dev/null)
    if [[ "$SUCCESS2" == "True" ]]; then
        pass "Tambah ke cart OK ($ITEM_COUNT item, cart_item_id=$CART_ITEM_ID)"
    else
        fail "Tambah ke cart gagal"
        show_json "$RESP2"
    fi

    print_test "PATCH /api/cart/$CART_ITEM_ID — Update qty"
    if [[ -n "$CART_ITEM_ID" ]]; then
        RESP3=$(call PATCH "/cart/$CART_ITEM_ID" '{"quantity": 3}' "$TOKEN")
        SUCCESS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
        if [[ "$SUCCESS3" == "True" ]]; then
            pass "Update qty berhasil"
        else
            fail "Update qty gagal"
            show_json "$RESP3"
        fi
    fi

    print_test "PATCH /api/cart/$CART_ITEM_ID/toggle-select — Toggle select"
    if [[ -n "$CART_ITEM_ID" ]]; then
        RESP4=$(call PATCH "/cart/$CART_ITEM_ID/toggle-select" "" "$TOKEN")
        SUCCESS4=$(echo "$RESP4" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
        if [[ "$SUCCESS4" == "True" ]]; then
            pass "Toggle select berhasil"
        else
            fail "Toggle select gagal"
            show_json "$RESP4"
        fi
    fi

    print_test "POST /api/cart/toggle-select-all — Select all"
    RESP5=$(call POST /cart/toggle-select-all '{"select_all": true}' "$TOKEN")
    SUCCESS5=$(echo "$RESP5" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
    if [[ "$SUCCESS5" == "True" ]]; then
        pass "Toggle select all berhasil"
    else
        fail "Toggle select all gagal"
        show_json "$RESP5"
    fi
fi

# ─── TEST 8: CHECKOUT ────────────────────────────────────────
print_header "8. CHECKOUT (AUTH)"

print_test "GET /api/checkout — Preview checkout"
RESP=$(call GET /checkout "" "$TOKEN")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    SUBTOTAL=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('subtotal',0))" 2>/dev/null)
    pass "Checkout preview OK (subtotal=Rp$SUBTOTAL)"
else
    fail "Checkout preview gagal"
    show_json "$RESP"
fi

print_test "POST /api/checkout — Buat order"
if [[ -n "$ADDRESS_ID" ]]; then
    RESP2=$(call POST /checkout "{
      \"address_id\": $ADDRESS_ID,
      \"payment_method\": \"cash_on_delivery\",
      \"notes\": \"Test order dari API test suite\"
    }" "$TOKEN")
    SUCCESS2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
    ORDER_ID=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('order_id',''))" 2>/dev/null)
    ORDER_NUM=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('order_number',''))" 2>/dev/null)
    if [[ "$SUCCESS2" == "True" && -n "$ORDER_ID" ]]; then
        pass "Order dibuat: $ORDER_NUM (id=$ORDER_ID)"
    else
        fail "Buat order gagal"
        show_json "$RESP2"
    fi
fi

# ─── TEST 9: ORDERS ──────────────────────────────────────────
print_header "9. ORDERS (AUTH)"

print_test "GET /api/orders — List orders"
RESP=$(call GET /orders "" "$TOKEN")
SUCCESS=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
TOTAL=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('pagination',{}).get('total',0))" 2>/dev/null)
if [[ "$SUCCESS" == "True" ]]; then
    pass "List orders OK ($TOTAL orders)"
    if [[ -z "$ORDER_ID" ]]; then
        ORDER_ID=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); items=d.get('data',{}).get('data',[]); print(items[0].get('id','') if items else '')" 2>/dev/null)
    fi
else
    fail "List orders gagal"
    show_json "$RESP"
fi

print_test "GET /api/orders?status=pending — Filter status"
RESP2=$(call GET "/orders?status=pending" "" "$TOKEN")
SUCCESS2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS2" == "True" ]]; then
    pass "Filter status=pending OK"
else
    fail "Filter status gagal"
fi

if [[ -n "$ORDER_ID" ]]; then
    print_test "GET /api/orders/$ORDER_ID — Detail order"
    RESP3=$(call GET "/orders/$ORDER_ID" "" "$TOKEN")
    STATUS=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('status',''))" 2>/dev/null)
    if [[ -n "$STATUS" ]]; then
        pass "Detail order OK (status=$STATUS)"
    else
        fail "Detail order gagal"
        show_json "$RESP3"
    fi

    print_test "POST /api/orders/$ORDER_ID/cancel — Cancel order"
    RESP4=$(call POST "/orders/$ORDER_ID/cancel" '{"cancel_reason": "Test cancel"}' "$TOKEN")
    SUCCESS4=$(echo "$RESP4" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
    if [[ "$SUCCESS4" == "True" ]]; then
        pass "Order berhasil dibatalkan"
    else
        MSG4=$(echo "$RESP4" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
        # Mungkin sudah lewat 2 jam atau status tidak bisa cancel
        if [[ "$MSG4" == *"tidak dapat dibatalkan"* ]]; then
            pass "Cancel ditolak dengan benar: '$MSG4'"
        else
            fail "Cancel gagal: $MSG4"
        fi
    fi
fi

# ─── TEST 10: PROFILE ────────────────────────────────────────
print_header "10. PROFILE (AUTH)"

print_test "GET /api/profile"
RESP=$(call GET /profile "" "$TOKEN")
NAME=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('name',''))" 2>/dev/null)
if [[ -n "$NAME" ]]; then
    pass "GET profile OK ($NAME)"
else
    fail "GET profile gagal"
    show_json "$RESP"
fi

print_test "PUT /api/profile — Update nama"
RESP2=$(call PUT /profile "{
  \"name\": \"Updated Test User\",
  \"email\": \"$TEST_EMAIL\",
  \"phone\": \"$TEST_PHONE\"
}" "$TOKEN")
SUCCESS2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
NEW_NAME=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('name',''))" 2>/dev/null)
if [[ "$SUCCESS2" == "True" && "$NEW_NAME" == "Updated Test User" ]]; then
    pass "Update profile OK (nama: $NEW_NAME)"
else
    fail "Update profile gagal"
    show_json "$RESP2"
fi

print_test "PUT /api/profile/password — Update password"
RESP3=$(call PUT /profile/password '{
  "current_password": "Password123!",
  "password": "NewPassword456@",
  "password_confirmation": "NewPassword456@"
}' "$TOKEN")
SUCCESS3=$(echo "$RESP3" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('success',''))" 2>/dev/null)
if [[ "$SUCCESS3" == "True" ]]; then
    pass "Update password OK"
else
    fail "Update password gagal"
    show_json "$RESP3"
fi

# ─── TEST 11: LOGOUT ─────────────────────────────────────────
print_header "11. AUTH — LOGOUT"

print_test "POST /api/logout"
RESP=$(call POST /logout "" "$TOKEN")
MSG=$(echo "$RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if [[ "$MSG" == *"berhasil"* ]]; then
    pass "Logout berhasil: '$MSG'"
else
    fail "Logout gagal"
    show_json "$RESP"
fi

print_test "GET /api/me — Setelah logout (harus 401)"
RESP2=$(call GET /me "" "$TOKEN")
MSG2=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('message',''))" 2>/dev/null)
if [[ "$MSG2" == *"Unauthenticated"* ]]; then
    pass "Token sudah tidak valid setelah logout"
else
    fail "Token masih aktif setelah logout!"
    show_json "$RESP2"
fi

# ─── SUMMARY ─────────────────────────────────────────────────
print_header "HASIL TEST"
TOTAL=$((PASS + FAIL))
echo -e "\n  ${GREEN}✓ PASS: $PASS${NC} / $TOTAL"
echo -e "  ${RED}✗ FAIL: $FAIL${NC} / $TOTAL\n"
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}  🎉 SEMUA TEST BERHASIL! API siap digunakan.${NC}\n"
else
    echo -e "${YELLOW}  ⚠  $FAIL test gagal. Cek output di atas untuk debug.${NC}\n"
fi
