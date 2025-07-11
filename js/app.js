// Main JavaScript file for the Fleet Management System

document.addEventListener('DOMContentLoaded', () => {
    console.log('Fleet Management System script loaded.');

    // Initialize Firebase
    // Make sure firebaseConfig is loaded before this script
    if (typeof firebase !== 'undefined' && typeof firebaseConfig !== 'undefined') {
        try {
            firebase.initializeApp(firebaseConfig);
            console.log("Firebase initialized successfully.");

            // Get references to Firebase services
            const auth = firebase.auth();
            const db = firebase.firestore();

            // Store them globally or pass them around as needed
            window.fbAuth = auth;
            window.fbAuth = auth;
            window.fbDb = db;

            // UI Elements
            const loginSection = document.getElementById('loginSection');
            const dashboardSection = document.getElementById('dashboardSection');
            const logoutButton = document.getElementById('logoutButton');
            const loginForm = document.getElementById('loginForm');
            const loginError = document.getElementById('loginError');

            // Vehicle Management UI Elements
            const showAddVehicleFormButton = document.getElementById('showAddVehicleFormButton');
            const vehicleFormSection = document.getElementById('vehicleFormSection');
            const vehicleForm = document.getElementById('vehicleForm');
            const vehicleFormTitle = document.getElementById('vehicleFormTitle');
            const cancelVehicleFormButton = document.getElementById('cancelVehicleFormButton');
            const vehicleList = document.getElementById('vehicleList');
            let currentVehicleId = null; // To store ID for editing

            // Function to show/hide sections
            const showLogin = () => {
                loginSection.classList.remove('hidden');
                dashboardSection.classList.add('hidden');
                logoutButton.classList.add('hidden');
            };

            const showDashboard = () => {
                loginSection.classList.add('hidden');
                dashboardSection.classList.remove('hidden');
                logoutButton.classList.remove('hidden');
            };

            // Handle Login
            loginForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                const email = loginForm.email.value;
                const password = loginForm.password.value;
                loginError.textContent = ''; // Clear previous errors

                try {
                    await fbAuth.signInWithEmailAndPassword(email, password);
                    // Auth state change will handle UI update
                    console.log('User logged in');
                    loginForm.reset();
                } catch (error) {
                    console.error('Login error:', error);
                    loginError.textContent = error.message;
                }
            });

            // Handle Logout
            logoutButton.addEventListener('click', async () => {
                try {
                    await fbAuth.signOut();
                    // Auth state change will handle UI update
                    console.log('User logged out');
                } catch (error) {
                    console.error('Logout error:', error);
                }
            });

            // Auth State Listener
            fbAuth.onAuthStateChanged(user => {
                if (user) {
                    console.log('User is signed in:', user);
                    showDashboard();
                    loadVehicles(); // Load vehicles when user is signed in
                } else {
                    console.log('User is signed out');
                    showLogin();
                    vehicleList.innerHTML = '<p class="text-gray-500">Please log in to see vehicles.</p>'; // Clear vehicles
                }
            });

            // --- Vehicle Management Functions ---

            // Show Add Vehicle Form
            showAddVehicleFormButton.addEventListener('click', () => {
                currentVehicleId = null; // Reset vehicle ID
                vehicleForm.reset(); // Clear form
                vehicleFormTitle.textContent = 'Add New Vehicle';
                document.getElementById('vehicleId').value = ''; // Clear hidden ID field
                vehicleFormSection.classList.remove('hidden');
            });

            // Cancel/Hide Vehicle Form
            cancelVehicleFormButton.addEventListener('click', () => {
                vehicleFormSection.classList.add('hidden');
                vehicleForm.reset();
                currentVehicleId = null;
            });

            // Handle Vehicle Form Submit (Add/Edit)
            vehicleForm.addEventListener('submit', async (e) => {
                e.preventDefault();
                if (!fbDb) {
                    console.error("Firestore not initialized");
                    alert("Error: Database not connected. Please try again later.");
                    return;
                }

                const vehicleData = {
                    make: vehicleForm.make.value,
                    model: vehicleForm.model.value,
                    year: parseInt(vehicleForm.year.value),
                    vin: vehicleForm.vin.value,
                    licensePlate: vehicleForm.licensePlate.value,
                    status: vehicleForm.status.value,
                    // Storing userId to enable per-user data if needed in future, or for rules
                    userId: fbAuth.currentUser ? fbAuth.currentUser.uid : null,
                    lastUpdated: firebase.firestore.FieldValue.serverTimestamp()
                };

                try {
                    if (currentVehicleId) { // Editing existing vehicle
                        await fbDb.collection('vehicles').doc(currentVehicleId).update(vehicleData);
                        console.log('Vehicle updated:', currentVehicleId);
                    } else { // Adding new vehicle
                        await fbDb.collection('vehicles').add(vehicleData);
                        console.log('Vehicle added');
                    }
                    vehicleForm.reset();
                    vehicleFormSection.classList.add('hidden');
                    currentVehicleId = null;
                } catch (error) {
                    console.error('Error saving vehicle: ', error);
                    alert('Error saving vehicle: ' + error.message);
                }
            });

            // Load and Display Vehicles
            const loadVehicles = () => {
                if (!fbDb || !fbAuth.currentUser) {
                    vehicleList.innerHTML = '<p class="text-gray-500">Please log in to see vehicles.</p>';
                    return;
                }

                // Example: Querying only vehicles for the current user
                // For a shared fleet, you might remove the .where('userId', '==', fbAuth.currentUser.uid)
                fbDb.collection('vehicles')
                    // .where('userId', '==', fbAuth.currentUser.uid) // Uncomment if vehicles are user-specific
                    .orderBy('lastUpdated', 'desc')
                    .onSnapshot(snapshot => {
                        if (snapshot.empty) {
                            vehicleList.innerHTML = '<p class="text-gray-500">No vehicles found. Add one to get started!</p>';
                            return;
                        }
                        let html = '<div class="overflow-x-auto"><table class="min-w-full bg-white"><thead><tr class="w-full h-16 border-gray-300 border-b py-8">';
                        html += '<th class="text-left pl-8 pr-6 text-sm text-gray-600">Make</th>';
                        html += '<th class="text-left pr-6 text-sm text-gray-600">Model</th>';
                        html += '<th class="text-left pr-6 text-sm text-gray-600">Year</th>';
                        html += '<th class="text-left pr-6 text-sm text-gray-600">VIN</th>';
                        html += '<th class="text-left pr-6 text-sm text-gray-600">License Plate</th>';
                        html += '<th class="text-left pr-6 text-sm text-gray-600">Status</th>';
                        html += '<th class="text-left pr-10 text-sm text-gray-600">Actions</th>';
                        html += '</tr></thead><tbody>';

                        snapshot.forEach(doc => {
                            const vehicle = doc.data();
                            const vehicleId = doc.id;
                            html += `<tr class="h-14 border-gray-300 border-b">
                                <td class="pl-8 pr-6 text-sm text-gray-800">${vehicle.make}</td>
                                <td class="pr-6 text-sm text-gray-800">${vehicle.model}</td>
                                <td class="pr-6 text-sm text-gray-800">${vehicle.year}</td>
                                <td class="pr-6 text-sm text-gray-800">${vehicle.vin}</td>
                                <td class="pr-6 text-sm text-gray-800">${vehicle.licensePlate}</td>
                                <td class="pr-6 text-sm text-gray-800">
                                    <span class="px-2 py-1 font-semibold leading-tight text-xs rounded-full ${
                                        vehicle.status === 'Available' ? 'bg-green-100 text-green-700' :
                                        vehicle.status === 'In Use' ? 'bg-yellow-100 text-yellow-700' :
                                        'bg-red-100 text-red-700'
                                    }">
                                        ${vehicle.status}
                                    </span>
                                </td>
                                <td class="pr-10 text-sm">
                                    <button data-id="${vehicleId}" class="edit-vehicle-btn text-blue-500 hover:text-blue-700 mr-2">Edit</button>
                                    <button data-id="${vehicleId}" class="delete-vehicle-btn text-red-500 hover:text-red-700">Delete</button>
                                </td>
                            </tr>`;
                        });
                        html += '</tbody></table></div>';
                        vehicleList.innerHTML = html;

                        // Add event listeners for new edit/delete buttons
                        document.querySelectorAll('.edit-vehicle-btn').forEach(button => {
                            button.addEventListener('click', handleEditVehicle);
                        });
                        document.querySelectorAll('.delete-vehicle-btn').forEach(button => {
                            button.addEventListener('click', handleDeleteVehicle);
                        });
                    }, error => {
                        console.error("Error loading vehicles: ", error);
                        vehicleList.innerHTML = '<p class="text-red-500">Error loading vehicles.</p>';
                    });
            };

            // Handle Edit Vehicle Button Click
            const handleEditVehicle = async (e) => {
                currentVehicleId = e.target.dataset.id;
                if (!fbDb) {
                    console.error("Firestore not initialized"); return;
                }
                try {
                    const docRef = fbDb.collection('vehicles').doc(currentVehicleId);
                    const doc = await docRef.get();
                    if (doc.exists) {
                        const data = doc.data();
                        vehicleForm.make.value = data.make;
                        vehicleForm.model.value = data.model;
                        vehicleForm.year.value = data.year;
                        vehicleForm.vin.value = data.vin;
                        vehicleForm.licensePlate.value = data.licensePlate;
                        vehicleForm.status.value = data.status;
                        document.getElementById('vehicleId').value = currentVehicleId; // Set hidden ID field

                        vehicleFormTitle.textContent = 'Edit Vehicle';
                        vehicleFormSection.classList.remove('hidden');
                    } else {
                        console.log("No such document!");
                        alert("Vehicle not found.");
                    }
                } catch (error) {
                    console.error("Error fetching vehicle for edit: ", error);
                    alert("Error fetching vehicle details.");
                }
            };

            // Handle Delete Vehicle Button Click
            const handleDeleteVehicle = async (e) => {
                const vehicleIdToDelete = e.target.dataset.id;
                if (!fbDb) {
                    console.error("Firestore not initialized"); return;
                }
                if (confirm('Are you sure you want to delete this vehicle?')) {
                    try {
                        await fbDb.collection('vehicles').doc(vehicleIdToDelete).delete();
                        console.log('Vehicle deleted:', vehicleIdToDelete);
                        // The onSnapshot listener in loadVehicles will automatically update the list
                    } catch (error) {
                        console.error('Error deleting vehicle: ', error);
                        alert('Error deleting vehicle: ' + error.message);
                    }
                }
            };

        } catch (e) {
            console.error("Error initializing Firebase: ", e);
            const appDiv = document.getElementById('app');
            if (appDiv) {
                appDiv.innerHTML = '<div class="container mx-auto p-4"><h1 class="text-2xl font-bold text-center text-red-500">Error initializing Firebase. Please check your configuration and ensure Firebase services (Auth, Firestore) are enabled in your project.</h1></div>';
            }
        }
    } else {
        console.error('Firebase or firebaseConfig is not defined. Make sure Firebase SDKs and firebase-config.js are loaded correctly.');
        const appDiv = document.getElementById('app');
        if (appDiv) {
            appDiv.innerHTML = '<div class="container mx-auto p-4"><h1 class="text-2xl font-bold text-center text-red-500">Error loading Firebase scripts. Please check the console.</h1></div>';
        }
    }

    // Initial app setup will go here (non-Firebase dependent parts)
    const currentYearSpan = document.getElementById('currentYear');
    if (currentYearSpan) {
        currentYearSpan.textContent = new Date().getFullYear();
    }
});
