@props([
    'name' => 'file',
    'accept' => 'image/*',
    'maxSize' => 2048, // 2MB in KB
    'currentImage' => null,
    'label' => 'Upload File'
])

<div class="space-y-3">
    <label class="form-label">{{ $label }} <span class="text-red-500">*</span></label>

    @if ($currentImage)
        <div class="mb-4">
            <img src="{{ $currentImage }}" alt="Current" class="w-32 h-32 object-cover rounded-xl border border-gray-200">
            <p class="text-xs text-gray-400 mt-1">Gambar saat ini. Upload baru untuk mengganti.</p>
        </div>
    @endif

    <!-- Hidden file input -->
    <input type="file" id="file-input-{{ $name }}" name="{{ $name }}" accept="{{ $accept }}" 
           class="hidden" data-max-size="{{ $maxSize }}">

    <!-- Drag & Drop Zone -->
    <div id="drop-zone-{{ $name }}"
         class="relative border-2 border-dashed border-gray-300 rounded-2xl p-8 text-center transition-all duration-200 cursor-pointer hover:border-herbal-400 hover:bg-herbal-50"
         data-file-input="file-input-{{ $name }}"
         data-preview-container="preview-container-{{ $name }}">

        <!-- Default state -->
        <div class="flex flex-col items-center gap-3">
            <svg class="w-12 h-12 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" 
                      d="M12 4v16m8-8H4M7 7l5-5 5 5M7 17l5 5 5-5" />
            </svg>
            <div>
                <p class="font-medium text-gray-700">Seret gambar ke sini</p>
                <p class="text-sm text-gray-500">atau klik untuk memilih file</p>
            </div>
            <p class="text-xs text-gray-400">Maksimal 2MB • JPG, PNG, WebP</p>
        </div>

        <!-- Dragging state (hidden by default) -->
        <div class="hidden drop-zone-dragging absolute inset-0 flex items-center justify-center rounded-2xl bg-herbal-50 border-2 border-herbal-400">
            <div class="text-center">
                <svg class="w-12 h-12 text-herbal-600 mx-auto mb-2 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16L3 12m0 0l4-4m-4 4h18" />
                </svg>
                <p class="font-medium text-herbal-700">Lepaskan file di sini</p>
            </div>
        </div>
    </div>

    <!-- Preview Container -->
    <div id="preview-container-{{ $name }}" class="hidden">
        <div class="relative w-40 h-40 rounded-2xl border-2 border-herbal-200 bg-herbal-50 overflow-hidden">
            <img id="preview-image-{{ $name }}" src="" alt="Preview" 
                 class="w-full h-full object-cover">
            <button type="button" 
                    id="delete-button-{{ $name }}"
                    class="absolute top-2 right-2 bg-red-500 hover:bg-red-600 text-white rounded-full p-1 transition-colors pointer-events-auto z-10"
                    data-file-input="file-input-{{ $name }}"
                    data-drop-zone="drop-zone-{{ $name }}"
                    data-preview-container="preview-container-{{ $name }}">
                <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
                </svg>
            </button>
            <div class="absolute inset-0 flex items-end p-2 bg-gradient-to-t from-black/50 to-transparent pointer-events-none">
                <p id="file-name-{{ $name }}" class="text-white text-xs font-medium truncate w-full"></p>
            </div>
        </div>
    </div>

    @error($name)
        <p class="text-red-500 text-xs mt-1">{{ $message }}</p>
    @enderror
</div>

<script>
// Drag & Drop upload handler for {{ $name }}
document.addEventListener('DOMContentLoaded', function() {
    const fileInput = document.getElementById('file-input-{{ $name }}');
    const dropZone = document.getElementById('drop-zone-{{ $name }}');
    const previewContainer = document.getElementById('preview-container-{{ $name }}');
    const previewImage = document.getElementById('preview-image-{{ $name }}');
    const fileName = document.getElementById('file-name-{{ $name }}');
    const maxSize = {{ $maxSize }} * 1024; // Convert KB to bytes
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    
    // Get all divs inside drop zone (for showing/hiding)
    const defaultState = dropZone.querySelector('div:first-child');
    const draggingState = dropZone.querySelector('.drop-zone-dragging');
    
    // Counter for tracking enter/leave events (to handle nested elements)
    let dragCounter = 0;

    // Click to upload
    dropZone.addEventListener('click', () => fileInput.click());

    // Handle file input change
    fileInput.addEventListener('change', (e) => {
        const files = e.target.files;
        if (files.length > 0) {
            handleFile(files[0]);
        }
    });

    // Handle delete preview button - gunakan event delegation
    document.addEventListener('click', function(e) {
        const deleteBtn = e.target.closest('#delete-button-{{ $name }}');
        if (deleteBtn) {
            e.preventDefault();
            e.stopPropagation();
            
            console.log('[DragDrop] Delete preview clicked for {{ $name }}');
            
            // Reset file input
            fileInput.value = '';
            
            // Reset preview image
            previewImage.src = '';
            fileName.textContent = '';
            
            // Hide preview container
            previewContainer.classList.add('hidden');
            
            // Show drop zone again
            dropZone.classList.remove('hidden');
            
            // Reset drag counter
            dragCounter = 0;
        }
    }, true); // <-- 'true' untuk capture phase

    // Prevent default drag behavior on document
    document.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.stopPropagation();
    }, false);

    document.addEventListener('drop', (e) => {
        e.preventDefault();
        e.stopPropagation();
    }, false);

    // Drag enter - increment counter
    dropZone.addEventListener('dragenter', (e) => {
        e.preventDefault();
        e.stopPropagation();
        dragCounter++;
        
        dropZone.classList.add('border-herbal-400', 'bg-herbal-50');
        if (draggingState) draggingState.classList.remove('hidden');
        if (defaultState) defaultState.classList.add('hidden');
    }, false);

    // Drag over - keep default prevented
    dropZone.addEventListener('dragover', (e) => {
        e.preventDefault();
        e.stopPropagation();
        e.dataTransfer.dropEffect = 'copy';
    }, false);

    // Drag leave - decrement counter, hide only if count reaches 0
    dropZone.addEventListener('dragleave', (e) => {
        e.preventDefault();
        e.stopPropagation();
        dragCounter--;
        
        if (dragCounter === 0) {
            dropZone.classList.remove('border-herbal-400', 'bg-herbal-50');
            if (draggingState) draggingState.classList.add('hidden');
            if (defaultState) defaultState.classList.remove('hidden');
        }
    }, false);

    // Drop - handle file
    dropZone.addEventListener('drop', (e) => {
        e.preventDefault();
        e.stopPropagation();
        
        // Reset counter and visual state
        dragCounter = 0;
        dropZone.classList.remove('border-herbal-400', 'bg-herbal-50');
        if (draggingState) draggingState.classList.add('hidden');
        if (defaultState) defaultState.classList.remove('hidden');

        // Get files from dataTransfer
        const files = e.dataTransfer.files;
        if (files && files.length > 0) {
            fileInput.files = files;
            handleFile(files[0]);
        }
    }, false);

    // Handle file validation and preview
    function handleFile(file) {
        // Validate file type
        if (!allowedTypes.includes(file.type)) {
            alert('❌ Hanya file gambar (JPG, PNG, WebP) yang diterima.');
            fileInput.value = '';
            dragCounter = 0;
            return;
        }

        // Validate file size
        if (file.size > maxSize) {
            alert(`❌ Ukuran file terlalu besar. Maksimal 2MB, file Anda ${(file.size / 1024 / 1024).toFixed(2)}MB`);
            fileInput.value = '';
            dragCounter = 0;
            return;
        }

        // Show preview
        const reader = new FileReader();
        reader.onload = (e) => {
            previewImage.src = e.target.result;
            fileName.textContent = file.name;
            dropZone.classList.add('hidden');
            previewContainer.classList.remove('hidden');
        };
        reader.readAsDataURL(file);
    }
});
</script>
