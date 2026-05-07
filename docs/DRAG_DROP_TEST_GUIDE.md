## 🧪 Drag & Drop Upload - Quick Test Guide

Saat sudah memperbaiki bug drag & drop, ikuti panduan ini untuk test:

---

### ✅ BEFORE YOU TEST

1. **Clear browser cache**
   ```bash
   npm run build  # Rebuild assets (if using Vite)
   # OR clear browser cache manually (Ctrl+Shift+Delete)
   ```

2. **Restart development server**
   ```bash
   npm run dev  # Restart
   ```

3. **Have ready**
   - File gambar (.jpg, .png, .webp)
   - File bukan gambar (.txt, .pdf) untuk test validasi
   - File > 2MB untuk test size validation

---

### 👉 TEST 1: Drag Image File (MAIN TEST)

**Steps:**
1. Navigate to `/admin/products/create` (Tambah Produk page)
2. Open Windows File Explorer (or Mac Finder)
3. Locate image file (JPG, PNG)
4. **DRAG** file directly onto the upload area
5. Expected result:
   - ✅ Visual feedback "Lepaskan file di sini" while dragging
   - ✅ Area turns green (border + background)
   - ✅ On drop: Preview appears
   - ❌ File does NOT open in new tab/window
   - ❌ No error in browser console

**Test Result**: ___________

---

### 👉 TEST 2: Cursor Feedback

**Steps:**
1. Keep file dragging in File Explorer
2. Move cursor OVER the upload area
3. Expected:
   - ✅ Cursor changes to copy icon (+ symbol)
   - ✅ Border turns green
   - ✅ "Lepaskan file di sini" visible

**Test Result**: ___________

---

### 👉 TEST 3: Visual Feedback Timing

**Steps:**
1. Drag file to area
2. Move file TO THE EDGE of upload area
3. Expected:
   - ✅ Visual stays green (tidak flickering)
   - ✅ Smooth, no jumping colors
4. Move file OUTSIDE area
5. Expected:
   - ✅ Visual resets to gray
   - ✅ Smooth transition

**Test Result**: ___________

---

### 👉 TEST 4: File Type Validation

**Steps:**
1. Try dragging NON-IMAGE file (.txt, .pdf)
2. Expected:
   - ✅ Alert appears: "❌ Hanya file gambar (JPG, PNG, WebP)"
   - ✅ File input clears
   - ✅ No preview shown

**Test Result**: ___________

---

### 👉 TEST 5: File Size Validation

**Steps:**
1. Find/create image file > 2MB
2. Drag to upload area
3. Expected:
   - ✅ Alert appears: "❌ Ukuran file terlalu besar. Maksimal 2MB..."
   - ✅ Shows actual size of file
   - ✅ File input clears
   - ✅ No preview shown

**Test Result**: ___________

---

### 👉 TEST 6: Click Upload (Fallback)

**Steps:**
1. Click on upload area (not drag)
2. Expected:
   - ✅ File picker dialog appears
3. Select image file
4. Expected:
   - ✅ Preview shows after selection

**Test Result**: ___________

---

### 👉 TEST 7: Preview Display

**Steps:**
1. Successfully drag or select image
2. Expected:
   - ✅ Upload area HIDDEN
   - ✅ Preview area VISIBLE
   - ✅ 160x160px image thumbnail shown
   - ✅ Filename displayed at bottom
   - ✅ Red X button to delete

**Test Result**: ___________

---

### 👉 TEST 8: Remove Preview

**Steps:**
1. After preview shown, click red X button
2. Expected:
   - ✅ Preview area HIDDEN
   - ✅ Upload area visible again
   - ✅ File input cleared
   - ✅ Can upload new file

**Test Result**: ___________

---

### 👉 TEST 9: Form Submission

**Steps:**
1. Upload image (drag or click)
2. Fill other required fields (name, price, stock, category)
3. Click "Tambah Produk" button
4. Expected:
   - ✅ Form submits successfully
   - ✅ Image saved to database
   - ✅ Product listing shows image

**Test Result**: ___________

---

### 👉 TEST 10: Edit Product Image

**Steps:**
1. Go to `/admin/products/{id}/edit` (Edit Product page)
2. Current image should show above upload area
3. Optional: Drag new image
4. Click "Simpan Perubahan"
5. Expected:
   - ✅ New image replaces old image
   - ✅ Or old image kept if no new upload

**Test Result**: ___________

---

### 👉 TEST 11: Multiple Products

**Steps:**
1. Open 2-3 product edit/create pages in different tabs
2. Upload different images in each tab
3. Expected:
   - ✅ Each tab independent
   - ✅ No cross-tab interference
   - ✅ Each image saved separately

**Test Result**: ___________

---

### 👉 TEST 12: Edge Cases

**A. Drag but NOT on upload area:**
- Expected: Normal browser behavior (no file pickup)

**B. Drag multiple files:**
- Expected: Only first file processed

**C. Drag while file input already has selection:**
- Expected: New drag replaces old selection

**D. Rapid drag in/out:**
- Expected: Smooth, no glitches

**Test Result**: ___________

---

### 📱 MOBILE TEST (Optional)

If testing on mobile:

**Steps:**
1. Open `/admin/products/create` on mobile browser
2. Tap upload area
3. Expected:
   - ✅ File picker appears
   - ✅ Can select from camera roll
   - ✅ Preview works

**Test Result**: ___________

---

### ❌ COMMON ISSUES & SOLUTIONS

| Issue | Possible Cause | Solution |
|-------|---|---|
| File opens in new tab | Cache not cleared | Clear cache + restart browser |
| No visual feedback | JS not loaded | Check Console (F12), rebuild |
| Preview not showing | FileReader error | Try smaller file, different format |
| Event not firing | Event listener not attached | Check Console for errors |
| Flickering colors | Counter bug | Refresh page, clear cache |

---

### 🐛 If Something Still Wrong

**Check browser console (F12 → Console):**

```javascript
// Check if element exists
document.getElementById('drop-zone-image')
// Should return: <div id="drop-zone-image" ...>

// Check if handler attached
// (Look for "drop-zone-image" in listeners)
// Right-click element → Inspect → Event Listeners tab
```

**Check HTML (F12 → Elements):**
- Look for `<div id="drop-zone-image">`
- Should have class `border-2 border-dashed`
- Should be visible on page

**Network tab issues:**
- Ensure `/service-worker.js` loaded (should be green 200)
- Check bundle size increased (means JS code added)

---

### ✅ SUCCESS CHECKLIST

If all tests pass:
- ✅ Drag file ke upload area
- ✅ Preview muncul
- ✅ File tidak dibuka di tab baru
- ✅ Validasi file type bekerja
- ✅ Validasi file size bekerja
- ✅ Click upload fallback bekerja
- ✅ Form submit successful
- ✅ Image saved to database
- ✅ Edit mode shows current image
- ✅ Multiple tabs work independent

**🎉 BUG FIXED!**

---

### 📞 Need Help?

If issue persists after all tests:

1. Check JavaScript console for specific errors
2. Verify component is in right location
3. Clear all caches (Vite, browser, database)
4. Restart all services (PHP, MySQL, npm)
5. Try fresh browser (incognito mode)

