// JavaScript for website interactivity

document.addEventListener('DOMContentLoaded', function() {
    // Mobile Menu Toggle
    const menuButton = document.getElementById('mobile-menu-button');
    const mobileMenu = document.getElementById('mobile-menu');

    if (menuButton && mobileMenu) {
        menuButton.addEventListener('click', function() {
            mobileMenu.classList.toggle('hidden');
        });
    }

    // Active Navigation Link Styling
    const currentLocation = window.location.pathname.split('/').pop(); // Get current page filename
    const navLinks = document.querySelectorAll('.nav-link'); // Use class selector

    navLinks.forEach(link => {
        const linkPage = link.getAttribute('href').split('/').pop();
        // For index.html, currentLocation might be empty or 'index.html'
        if (linkPage === currentLocation || (currentLocation === '' && linkPage === 'index.html')) {
            link.classList.add('text-blue-600', 'font-semibold'); // Active link styles
            link.classList.remove('text-gray-700');
        }
    });


    // Smooth scrolling for on-page anchor links (if any are added back)
    const onPageNavLinks = document.querySelectorAll('a[href^="#"]'); // More generic selector
    onPageNavLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            const href = this.getAttribute('href');
            // Check if it's truly an on-page link and not just "#" for placeholder
            if (href.length > 1 && href.startsWith('#')) {
                const targetElement = document.querySelector(href);
                if (targetElement) {
                    e.preventDefault();
                    targetElement.scrollIntoView({
                        behavior: 'smooth'
                    });
                }
            } else if (href === "#") { // If it's just "#", prevent default but do nothing else or scroll to top
                e.preventDefault();
                // window.scrollTo({ top: 0, behavior: 'smooth' }); // Optional: scroll to top for "#"
            }
            // If it's a full URL (e.g. index.html#some-section), normal browser navigation will handle it.
        });
    });

    // Contact Form Submission (remains the same, but ensure it's on contact.html or loaded conditionally)
    const contactForm = document.getElementById('contactForm');
    const formFeedback = document.getElementById('formFeedback');

    if (contactForm) {
        contactForm.addEventListener('submit', function(e) {
            e.preventDefault(); // Prevent actual submission for now

            // Basic Validation
            const name = document.getElementById('name').value.trim();
            const email = document.getElementById('email').value.trim();
            const subject = document.getElementById('subject').value.trim();
            const message = document.getElementById('message').value.trim();

            if (!name || !email || !subject || !message) {
                displayFeedback('Please fill in all fields.', 'red');
                return;
            }

            if (!validateEmail(email)) {
                displayFeedback('Please enter a valid email address.', 'red');
                return;
            }

            // Simulate form submission
            // In a real application, you would send this data to a server
            console.log('Form submitted with:');
            console.log('Name:', name);
            console.log('Email:', email);
            console.log('Subject:', subject);
            console.log('Message:', message);

            displayFeedback('Thank you for your message! We will get back to you soon.', 'green');
            contactForm.reset(); // Reset form fields
        });
    }

    function displayFeedback(message, color) {
        if (formFeedback) {
            formFeedback.textContent = message;
            formFeedback.className = `mb-4 text-center p-3 rounded-md text-sm ${color === 'green' ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}`;
        } else {
            // Fallback if formFeedback element isn't present for some reason
            alert(message);
        }
    }

    function validateEmail(email) {
        const re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
        return re.test(String(email).toLowerCase());
    }

    // Optional: Add a subtle scroll animation for elements appearing
    const animatedSections = document.querySelectorAll('#services .grid > div, #about .grid > div');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-up'); // This class would need to be defined in CSS
                observer.unobserve(entry.target); // Optional: stop observing after animation
            }
        });
    }, { threshold: 0.1 });

    animatedSections.forEach(section => {
        observer.observe(section);
    });

});

// If you need custom CSS beyond Tailwind, you can add it in style.css
// For example, for the fade-in-up animation:
/*
In style.css:

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.fade-in-up {
  animation: fadeInUp 0.5s ease-out forwards;
}
*/
