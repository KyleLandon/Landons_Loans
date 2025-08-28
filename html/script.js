// Landon's Loans UI JavaScript
let currentLoanData = null;
let currentLoans = [];

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeEventListeners();
});

// Initialize all event listeners
function initializeEventListeners() {
    // Modal close buttons
    document.querySelectorAll('.close').forEach(closeBtn => {
        closeBtn.addEventListener('click', function() {
            const modalId = this.getAttribute('data-modal');
            closeModal(modalId);
        });
    });

    // Close buttons
    document.querySelectorAll('[data-close]').forEach(closeBtn => {
        closeBtn.addEventListener('click', function() {
            const modalId = this.getAttribute('data-close');
            closeModal(modalId);
        });
    });

    // Tab switching
    document.querySelectorAll('.tab-button').forEach(tabBtn => {
        tabBtn.addEventListener('click', function() {
            switchTab(this.getAttribute('data-tab'));
        });
    });

    // Loan application form
    const loanAmountInput = document.getElementById('loanAmount');
    const loanTermSelect = document.getElementById('loanTerm');
    
    if (loanAmountInput && loanTermSelect) {
        loanAmountInput.addEventListener('input', updateLoanCalculation);
        loanTermSelect.addEventListener('change', updateLoanCalculation);
    }

    // Submit loan application
    const submitLoanBtn = document.getElementById('submitLoanApplication');
    if (submitLoanBtn) {
        submitLoanBtn.addEventListener('click', submitLoanApplication);
    }

    // Payment form
    const paymentLoanSelect = document.getElementById('paymentLoan');
    if (paymentLoanSelect) {
        paymentLoanSelect.addEventListener('change', updatePaymentDetails);
    }

    // Payment amount buttons
    const payMinimumBtn = document.getElementById('payMinimum');
    const payFullBtn = document.getElementById('payFull');
    
    if (payMinimumBtn) {
        payMinimumBtn.addEventListener('click', function() {
            const selectedLoan = getSelectedPaymentLoan();
            if (selectedLoan) {
                document.getElementById('paymentAmount').value = selectedLoan.daily_payment;
            }
        });
    }

    if (payFullBtn) {
        payFullBtn.addEventListener('click', function() {
            const selectedLoan = getSelectedPaymentLoan();
            if (selectedLoan) {
                document.getElementById('paymentAmount').value = selectedLoan.balance;
            }
        });
    }

    // Submit payment
    const submitPaymentBtn = document.getElementById('submitPayment');
    if (submitPaymentBtn) {
        submitPaymentBtn.addEventListener('click', submitPayment);
    }

    // Staff functions
    const lookupPlayerBtn = document.getElementById('lookupPlayer');
    if (lookupPlayerBtn) {
        lookupPlayerBtn.addEventListener('click', lookupPlayer);
    }

    const issueStaffLoanBtn = document.getElementById('issueStaffLoan');
    if (issueStaffLoanBtn) {
        issueStaffLoanBtn.addEventListener('click', issueStaffLoan);
    }

    // Close modal when clicking outside
    window.addEventListener('click', function(event) {
        if (event.target.classList.contains('modal')) {
            console.log('[Landon\'s Loans] Modal background clicked, closing modal');
            closeModal(event.target.id);
        }
    });
    
    // Also handle clicks on close buttons
    document.addEventListener('click', function(event) {
        if (event.target.classList.contains('close') || event.target.hasAttribute('data-close')) {
            console.log('[Landon\'s Loans] Close button clicked');
            const modalId = event.target.getAttribute('data-modal') || event.target.getAttribute('data-close');
            if (modalId) {
                closeModal(modalId);
            } else {
                closeAllModals();
            }
        }
    });
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    console.log('[Landon\'s Loans] Received NUI message:', data.type, data);
    
    switch(data.type) {
        case 'showCreditScore':
            console.log('[Landon\'s Loans] Showing credit score UI');
            showCreditScore(data.data);
            break;
        case 'showLoanApplication':
            showLoanApplication(data.data);
            break;
        case 'showActiveLoans':
            showActiveLoans(data.data);
            break;
        case 'showPaymentUI':
            showPaymentUI(data.data);
            break;
        case 'showStaffMenu':
            showStaffMenu(data.data);
            break;
        case 'showStaffCreditData':
            showStaffCreditData(data.data);
            break;
        case 'showStaffLoanData':
            showStaffLoanData(data.data);
            break;
        case 'showNotification':
            showNotification(data.data.message, data.data.type, data.data.duration);
            break;
        case 'showProgress':
            showProgress(data.data.message, data.data.duration);
            break;
        case 'forceClose':
            closeAllModals();
            break;
    }
});

// Modal Functions
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'block';
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = 'auto';
    }
    
    // Only close NUI focus if no other modals are open
    const openModals = document.querySelectorAll('.modal[style*="block"]');
    if (openModals.length === 0) {
        // Post message to close NUI
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
}

function closeAllModals() {
    console.log('[Landon\'s Loans] Closing all modals');
    document.querySelectorAll('.modal').forEach(modal => {
        modal.style.display = 'none';
    });
    document.body.style.overflow = 'auto';
    
    // Always close NUI when closing all modals
    console.log('[Landon\'s Loans] Sending closeUI message to client');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(() => {
        console.log('[Landon\'s Loans] closeUI message sent successfully');
    }).catch(err => {
        console.error('[Landon\'s Loans] Failed to send closeUI message:', err);
    });
}

// Credit Score Display
function showCreditScore(data) {
    console.log('[Landon\'s Loans] showCreditScore called with data:', data);
    closeAllModals();
    
    const scoreNumber = document.getElementById('creditScoreNumber');
    const creditRating = document.getElementById('creditRating');
    const scoreCircle = document.querySelector('.score-circle');
    
    console.log('[Landon\'s Loans] Found elements:', scoreNumber, creditRating, scoreCircle);
    
    if (scoreNumber) scoreNumber.textContent = data.score;
    if (creditRating) creditRating.textContent = data.rating;
    
    // Update score circle color
    if (scoreCircle) {
        scoreCircle.className = 'score-circle';
        if (data.score < 580) scoreCircle.classList.add('poor');
        else if (data.score < 620) scoreCircle.classList.add('fair');
        else if (data.score < 680) scoreCircle.classList.add('good');
        else scoreCircle.classList.add('excellent');
    }
    
    console.log('[Landon\'s Loans] Opening credit score modal');
    openModal('creditScoreModal');
}

// Loan Application
function showLoanApplication(data) {
    closeAllModals();
    currentLoanData = data;
    
    // Update info cards
    document.getElementById('appCreditScore').textContent = data.creditScore;
    document.getElementById('appBankBalance').textContent = formatCurrency(data.bankBalance);
    document.getElementById('appInterestRate').textContent = data.interestRate + '%';
    document.getElementById('appMaxAmount').textContent = formatCurrency(data.maxLoanAmount);
    
    // Update form limits
    const loanAmountInput = document.getElementById('loanAmount');
    if (loanAmountInput) {
        loanAmountInput.max = data.maxLoanAmount;
        loanAmountInput.placeholder = `Max: ${formatCurrency(data.maxLoanAmount)}`;
    }
    
    // Clear previous values
    document.getElementById('loanAmount').value = '';
    document.getElementById('loanTerm').selectedIndex = 0;
    updateLoanCalculation();
    
    openModal('loanApplicationModal');
}

// Active Loans Display
function showActiveLoans(data) {
    closeAllModals();
    currentLoans = data.loans;
    
    const container = document.getElementById('activeLoansContainer');
    container.innerHTML = '';
    
    if (data.loans.length === 0) {
        container.innerHTML = '<div class="no-loans">You have no active loans.</div>';
    } else {
        data.loans.forEach(loan => {
            const loanElement = createLoanElement(loan);
            container.appendChild(loanElement);
        });
    }
    
    openModal('activeLoansModal');
}

// Payment UI
function showPaymentUI(data) {
    closeAllModals();
    currentLoans = data.loans;
    
    const loanSelect = document.getElementById('paymentLoan');
    loanSelect.innerHTML = '<option value="">Select a loan to pay</option>';
    
    data.loans.forEach(loan => {
        const option = document.createElement('option');
        option.value = loan.loan_id;
        option.textContent = `Loan #${loan.loan_id} - ${formatCurrency(loan.balance)} remaining`;
        loanSelect.appendChild(option);
    });
    
    // Clear form
    document.getElementById('paymentAmount').value = '';
    document.getElementById('paymentLoanDetails').style.display = 'none';
    
    openModal('paymentModal');
}

// Staff Menu
function showStaffMenu(data) {
    closeAllModals();
    openModal('staffMenuModal');
    switchTab('issueLoans');
}

// Helper Functions
function formatCurrency(amount) {
    return '$' + amount.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
}

function updateLoanCalculation() {
    if (!currentLoanData) return;
    
    const amount = parseFloat(document.getElementById('loanAmount').value) || 0;
    const term = parseInt(document.getElementById('loanTerm').value) || 7;
    const interestRate = currentLoanData.interestRate;
    
    const interest = amount * (interestRate / 100);
    const total = amount + interest;
    const dailyPayment = Math.ceil(total / term);
    
    document.getElementById('calcLoanAmount').textContent = formatCurrency(amount);
    document.getElementById('calcInterest').textContent = formatCurrency(interest);
    document.getElementById('calcTotal').textContent = formatCurrency(total);
    document.getElementById('calcDailyPayment').textContent = formatCurrency(dailyPayment);
}

function updatePaymentDetails() {
    const selectedLoanId = document.getElementById('paymentLoan').value;
    const detailsDiv = document.getElementById('paymentLoanDetails');
    
    if (!selectedLoanId) {
        detailsDiv.style.display = 'none';
        return;
    }
    
    const loan = currentLoans.find(l => l.loan_id == selectedLoanId);
    if (!loan) return;
    
    document.getElementById('paymentCurrentBalance').textContent = formatCurrency(loan.balance);
    document.getElementById('paymentDailyAmount').textContent = formatCurrency(loan.daily_payment);
    document.getElementById('paymentNextDue').textContent = formatDate(loan.next_payment_due);
    
    detailsDiv.style.display = 'block';
}

function getSelectedPaymentLoan() {
    const selectedLoanId = document.getElementById('paymentLoan').value;
    return currentLoans.find(l => l.loan_id == selectedLoanId);
}

function createLoanElement(loan) {
    const div = document.createElement('div');
    div.className = 'loan-item';
    
    const statusClass = loan.days_overdue > 0 ? 'overdue' : 'active';
    
    div.innerHTML = `
        <div class="loan-header">
            <div class="loan-type">${loan.loan_type} Loan</div>
            <div class="loan-status ${statusClass}">${statusClass}</div>
        </div>
        <div class="loan-details">
            <div class="detail-row">
                <span>Loan ID:</span>
                <span>#${loan.loan_id}</span>
            </div>
            <div class="detail-row">
                <span>Original Amount:</span>
                <span>${formatCurrency(loan.original_amount)}</span>
            </div>
            <div class="detail-row">
                <span>Current Balance:</span>
                <span>${formatCurrency(loan.balance)}</span>
            </div>
            <div class="detail-row">
                <span>Interest Rate:</span>
                <span>${loan.interest_rate}%</span>
            </div>
            <div class="detail-row">
                <span>Daily Payment:</span>
                <span>${formatCurrency(loan.daily_payment)}</span>
            </div>
            <div class="detail-row">
                <span>Days Remaining:</span>
                <span>${loan.days_remaining}</span>
            </div>
            <div class="detail-row">
                <span>Next Payment Due:</span>
                <span>${formatDate(loan.next_payment_due)}</span>
            </div>
            ${loan.days_overdue > 0 ? `
            <div class="detail-row">
                <span>Days Overdue:</span>
                <span style="color: red;">${loan.days_overdue}</span>
            </div>
            ` : ''}
        </div>
    `;
    
    return div;
}

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.tab-button').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`[data-tab="${tabName}"]`).classList.add('active');
    
    // Update tab content
    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
    });
    document.getElementById(tabName).classList.add('active');
}

// Form Submissions
function submitLoanApplication() {
    console.log('[Landon\'s Loans] submitLoanApplication called');
    
    const amount = parseFloat(document.getElementById('loanAmount').value);
    const term = parseInt(document.getElementById('loanTerm').value);
    
    console.log('[Landon\'s Loans] Form values - Amount:', amount, 'Term:', term);
    console.log('[Landon\'s Loans] Current loan data:', currentLoanData);
    
    if (!amount || amount < 1000) {
        console.log('[Landon\'s Loans] Validation failed - amount too low');
        showNotification('Please enter a valid loan amount (minimum $1,000)', 'error');
        return;
    }
    
    if (!currentLoanData || amount > currentLoanData.maxLoanAmount) {
        console.log('[Landon\'s Loans] Validation failed - amount exceeds max');
        showNotification('Loan amount exceeds your maximum limit', 'error');
        return;
    }
    
    console.log('[Landon\'s Loans] Validation passed, sending loan application');
    showProgress('Processing loan application...', 3000);
    
    const requestData = {
        amount: amount,
        term: term
    };
    
    console.log('[Landon\'s Loans] Sending request data:', requestData);
    
    fetch(`https://${GetParentResourceName()}/applyForLoan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(requestData)
    }).then(response => {
        console.log('[Landon\'s Loans] Fetch response received:', response);
        // Don't try to parse JSON since QBCore NUI callbacks return text
        return response.text();
    }).then(data => {
        console.log('[Landon\'s Loans] Response data:', data);
        // Close the modal after successful submission
        closeAllModals();
    }).catch(error => {
        console.error('[Landon\'s Loans] Fetch error:', error);
    });
}

function submitPayment() {
    const loanId = document.getElementById('paymentLoan').value;
    const amount = parseFloat(document.getElementById('paymentAmount').value);
    
    if (!loanId) {
        showNotification('Please select a loan', 'error');
        return;
    }
    
    if (!amount || amount <= 0) {
        showNotification('Please enter a valid payment amount', 'error');
        return;
    }
    
    const loan = getSelectedPaymentLoan();
    if (amount > loan.balance) {
        showNotification('Payment amount cannot exceed loan balance', 'error');
        return;
    }
    
    showProgress('Processing payment...', 2000);
    
    fetch(`https://${GetParentResourceName()}/makePayment`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            loanId: parseInt(loanId),
            amount: amount
        })
    });
}

function lookupPlayer() {
    const citizenId = document.getElementById('staffCitizenId').value.trim();
    
    if (!citizenId) {
        showNotification('Please enter a citizen ID', 'error');
        return;
    }
    
    fetch(`https://${GetParentResourceName()}/staffLookupPlayer`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            citizenid: citizenId
        })
    });
}

function issueStaffLoan() {
    const citizenId = document.getElementById('staffCitizenId').value.trim();
    const amount = parseFloat(document.getElementById('staffLoanAmount').value);
    const term = parseInt(document.getElementById('staffLoanTerm').value);
    const interestRate = parseFloat(document.getElementById('staffInterestRate').value);
    
    if (!citizenId) {
        showNotification('Please enter a citizen ID', 'error');
        return;
    }
    
    if (!amount || amount < 5000) {
        showNotification('Please enter a valid loan amount (minimum $5,000)', 'error');
        return;
    }
    
    if (!term || term < 7) {
        showNotification('Please enter a valid loan term (minimum 7 days)', 'error');
        return;
    }
    
    if (!interestRate || interestRate < 3) {
        showNotification('Please enter a valid interest rate (minimum 3%)', 'error');
        return;
    }
    
    showProgress('Processing staff loan...', 3000);
    
    fetch(`https://${GetParentResourceName()}/staffApplyLoan`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            citizenid: citizenId,
            amount: amount,
            term: term,
            interestRate: interestRate
        })
    });
}

// Notification System
function showNotification(message, type = 'info', duration = 5000) {
    const container = document.getElementById('notificationContainer');
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    container.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, duration);
}

// Progress Overlay
function showProgress(message, duration = 3000) {
    const overlay = document.getElementById('loadingOverlay');
    const text = overlay.querySelector('.loading-text');
    
    text.textContent = message;
    overlay.style.display = 'flex';
    
    setTimeout(() => {
        overlay.style.display = 'none';
    }, duration);
}

// Escape key handler
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' || event.keyCode === 27) {
        event.preventDefault();
        closeAllModals();
    }
});

// Also handle when window loses focus
window.addEventListener('blur', function() {
    // Don't auto-close on blur as it can be annoying
    // User should explicitly close with ESC or clicking X
});

// Resource name helper
function GetParentResourceName() {
    return window.location.hostname;
}
