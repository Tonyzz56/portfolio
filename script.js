// JavaScript for website interactivity

document.addEventListener('DOMContentLoaded', function() {
    // Smooth scrolling for navigation links
    const navLinks = document.querySelectorAll('header nav a[href^="#"]');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            let targetId = this.getAttribute('href');
            // Ensure targetId is not just "#" and an element with that ID exists
            if (targetId.length > 1 && document.querySelector(targetId)) {
                document.querySelector(targetId).scrollIntoView({
                    behavior: 'smooth'
                });
            } else if (targetId === "#") { // Link to home/top
                 window.scrollTo({ top: 0, behavior: 'smooth' });
            }
        });
    });

    // Contact Form Submission
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
