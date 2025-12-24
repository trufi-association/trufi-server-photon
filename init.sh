#!/bin/bash

# =============================================================================
# init.sh - Interactive script to download Photon data by country
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GraphHopper base URL
BASE_URL="https://download1.graphhopper.com/public/extracts/by-country-code"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------

print_header() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Photon Data Downloader - Trufi Server${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_info() {
    echo -e "${BLUE}$1${NC}"
}

# -----------------------------------------------------------------------------
# Check dependencies
# -----------------------------------------------------------------------------

check_dependencies() {
    local missing_deps=()

    echo "Checking dependencies..."
    echo ""

    # Check wget
    if command -v wget &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} wget installed"
    else
        echo -e "  ${RED}✗${NC} wget NOT found"
        missing_deps+=("wget")
    fi

    # Check tar
    if command -v tar &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} tar installed"
    else
        echo -e "  ${RED}✗${NC} tar NOT found"
        missing_deps+=("tar")
    fi

    # Check bzip2
    if command -v bzip2 &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} bzip2 installed"
    else
        echo -e "  ${RED}✗${NC} bzip2 NOT found"
        missing_deps+=("bzip2")
    fi

    echo ""

    # If dependencies are missing, show installation instructions
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Installation instructions:"
        echo ""

        # Detect operating system
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  macOS (Homebrew):"
            echo "    brew install ${missing_deps[*]}"
        elif command -v apt-get &> /dev/null; then
            echo "  Ubuntu/Debian:"
            echo "    sudo apt-get update && sudo apt-get install -y ${missing_deps[*]}"
        elif command -v dnf &> /dev/null; then
            echo "  Fedora:"
            echo "    sudo dnf install -y ${missing_deps[*]}"
        elif command -v yum &> /dev/null; then
            echo "  CentOS/RHEL:"
            echo "    sudo yum install -y ${missing_deps[*]}"
        elif command -v pacman &> /dev/null; then
            echo "  Arch Linux:"
            echo "    sudo pacman -S ${missing_deps[*]}"
        else
            echo "  Please install manually: ${missing_deps[*]}"
        fi
        echo ""
        exit 1
    fi

    print_success "All dependencies are installed."
}

# -----------------------------------------------------------------------------
# Get list of available countries
# -----------------------------------------------------------------------------

get_available_countries() {
    echo ""
    print_info "Fetching available countries from GraphHopper..."
    echo ""

    # Download HTML index and extract country codes
    local html_content
    html_content=$(wget -q -O - "$BASE_URL/" 2>/dev/null) || {
        print_error "Could not connect to $BASE_URL"
        echo "Please check your internet connection."
        exit 1
    }

    # Extract country codes (2-letter directories)
    COUNTRIES=$(echo "$html_content" | grep -oE 'href="[a-z]{2}/"' | sed 's/href="//g' | sed 's/\/"//g' | sort -u)

    if [ -z "$COUNTRIES" ]; then
        print_error "Could not fetch available countries."
        exit 1
    fi

    # Count countries
    local count
    count=$(echo "$COUNTRIES" | wc -l | tr -d ' ')
    print_success "Found $count available countries/territories."
}

# -----------------------------------------------------------------------------
# ISO code to country name mapping
# -----------------------------------------------------------------------------

get_country_name() {
    local code="$1"
    case "$code" in
        ad) echo "Andorra" ;;
        ae) echo "United Arab Emirates" ;;
        af) echo "Afghanistan" ;;
        ag) echo "Antigua and Barbuda" ;;
        ai) echo "Anguilla" ;;
        al) echo "Albania" ;;
        am) echo "Armenia" ;;
        ao) echo "Angola" ;;
        aq) echo "Antarctica" ;;
        ar) echo "Argentina" ;;
        as) echo "American Samoa" ;;
        at) echo "Austria" ;;
        au) echo "Australia" ;;
        aw) echo "Aruba" ;;
        ax) echo "Aland Islands" ;;
        az) echo "Azerbaijan" ;;
        ba) echo "Bosnia and Herzegovina" ;;
        bb) echo "Barbados" ;;
        bd) echo "Bangladesh" ;;
        be) echo "Belgium" ;;
        bf) echo "Burkina Faso" ;;
        bg) echo "Bulgaria" ;;
        bh) echo "Bahrain" ;;
        bi) echo "Burundi" ;;
        bj) echo "Benin" ;;
        bl) echo "Saint Barthelemy" ;;
        bm) echo "Bermuda" ;;
        bn) echo "Brunei" ;;
        bo) echo "Bolivia" ;;
        bq) echo "Caribbean Netherlands" ;;
        br) echo "Brazil" ;;
        bs) echo "Bahamas" ;;
        bt) echo "Bhutan" ;;
        bv) echo "Bouvet Island" ;;
        bw) echo "Botswana" ;;
        by) echo "Belarus" ;;
        bz) echo "Belize" ;;
        ca) echo "Canada" ;;
        cc) echo "Cocos Islands" ;;
        cd) echo "DR Congo" ;;
        cf) echo "Central African Republic" ;;
        cg) echo "Republic of Congo" ;;
        ch) echo "Switzerland" ;;
        ci) echo "Ivory Coast" ;;
        ck) echo "Cook Islands" ;;
        cl) echo "Chile" ;;
        cm) echo "Cameroon" ;;
        cn) echo "China" ;;
        co) echo "Colombia" ;;
        cr) echo "Costa Rica" ;;
        cu) echo "Cuba" ;;
        cv) echo "Cape Verde" ;;
        cw) echo "Curacao" ;;
        cx) echo "Christmas Island" ;;
        cy) echo "Cyprus" ;;
        cz) echo "Czech Republic" ;;
        de) echo "Germany" ;;
        dj) echo "Djibouti" ;;
        dk) echo "Denmark" ;;
        dm) echo "Dominica" ;;
        do) echo "Dominican Republic" ;;
        dz) echo "Algeria" ;;
        ec) echo "Ecuador" ;;
        ee) echo "Estonia" ;;
        eg) echo "Egypt" ;;
        eh) echo "Western Sahara" ;;
        er) echo "Eritrea" ;;
        es) echo "Spain" ;;
        et) echo "Ethiopia" ;;
        fi) echo "Finland" ;;
        fj) echo "Fiji" ;;
        fk) echo "Falkland Islands" ;;
        fm) echo "Micronesia" ;;
        fo) echo "Faroe Islands" ;;
        fr) echo "France" ;;
        ga) echo "Gabon" ;;
        gb) echo "United Kingdom" ;;
        gd) echo "Grenada" ;;
        ge) echo "Georgia" ;;
        gf) echo "French Guiana" ;;
        gg) echo "Guernsey" ;;
        gh) echo "Ghana" ;;
        gi) echo "Gibraltar" ;;
        gl) echo "Greenland" ;;
        gm) echo "Gambia" ;;
        gn) echo "Guinea" ;;
        gp) echo "Guadeloupe" ;;
        gq) echo "Equatorial Guinea" ;;
        gr) echo "Greece" ;;
        gs) echo "South Georgia" ;;
        gt) echo "Guatemala" ;;
        gu) echo "Guam" ;;
        gw) echo "Guinea-Bissau" ;;
        gy) echo "Guyana" ;;
        hk) echo "Hong Kong" ;;
        hm) echo "Heard and McDonald Islands" ;;
        hn) echo "Honduras" ;;
        hr) echo "Croatia" ;;
        ht) echo "Haiti" ;;
        hu) echo "Hungary" ;;
        id) echo "Indonesia" ;;
        ie) echo "Ireland" ;;
        il) echo "Israel" ;;
        im) echo "Isle of Man" ;;
        in) echo "India" ;;
        io) echo "British Indian Ocean Territory" ;;
        iq) echo "Iraq" ;;
        ir) echo "Iran" ;;
        is) echo "Iceland" ;;
        it) echo "Italy" ;;
        je) echo "Jersey" ;;
        jm) echo "Jamaica" ;;
        jo) echo "Jordan" ;;
        jp) echo "Japan" ;;
        ke) echo "Kenya" ;;
        kg) echo "Kyrgyzstan" ;;
        kh) echo "Cambodia" ;;
        ki) echo "Kiribati" ;;
        km) echo "Comoros" ;;
        kn) echo "Saint Kitts and Nevis" ;;
        kp) echo "North Korea" ;;
        kr) echo "South Korea" ;;
        kw) echo "Kuwait" ;;
        ky) echo "Cayman Islands" ;;
        kz) echo "Kazakhstan" ;;
        la) echo "Laos" ;;
        lb) echo "Lebanon" ;;
        lc) echo "Saint Lucia" ;;
        li) echo "Liechtenstein" ;;
        lk) echo "Sri Lanka" ;;
        lr) echo "Liberia" ;;
        ls) echo "Lesotho" ;;
        lt) echo "Lithuania" ;;
        lu) echo "Luxembourg" ;;
        lv) echo "Latvia" ;;
        ly) echo "Libya" ;;
        ma) echo "Morocco" ;;
        mc) echo "Monaco" ;;
        md) echo "Moldova" ;;
        me) echo "Montenegro" ;;
        mf) echo "Saint Martin" ;;
        mg) echo "Madagascar" ;;
        mh) echo "Marshall Islands" ;;
        mk) echo "North Macedonia" ;;
        ml) echo "Mali" ;;
        mm) echo "Myanmar" ;;
        mn) echo "Mongolia" ;;
        mo) echo "Macau" ;;
        mp) echo "Northern Mariana Islands" ;;
        mq) echo "Martinique" ;;
        mr) echo "Mauritania" ;;
        ms) echo "Montserrat" ;;
        mt) echo "Malta" ;;
        mu) echo "Mauritius" ;;
        mv) echo "Maldives" ;;
        mw) echo "Malawi" ;;
        mx) echo "Mexico" ;;
        my) echo "Malaysia" ;;
        mz) echo "Mozambique" ;;
        na) echo "Namibia" ;;
        nc) echo "New Caledonia" ;;
        ne) echo "Niger" ;;
        nf) echo "Norfolk Island" ;;
        ng) echo "Nigeria" ;;
        ni) echo "Nicaragua" ;;
        nl) echo "Netherlands" ;;
        no) echo "Norway" ;;
        np) echo "Nepal" ;;
        nr) echo "Nauru" ;;
        nu) echo "Niue" ;;
        nz) echo "New Zealand" ;;
        om) echo "Oman" ;;
        pa) echo "Panama" ;;
        pe) echo "Peru" ;;
        pf) echo "French Polynesia" ;;
        pg) echo "Papua New Guinea" ;;
        ph) echo "Philippines" ;;
        pk) echo "Pakistan" ;;
        pl) echo "Poland" ;;
        pm) echo "Saint Pierre and Miquelon" ;;
        pn) echo "Pitcairn Islands" ;;
        pr) echo "Puerto Rico" ;;
        ps) echo "Palestine" ;;
        pt) echo "Portugal" ;;
        pw) echo "Palau" ;;
        py) echo "Paraguay" ;;
        qa) echo "Qatar" ;;
        re) echo "Reunion" ;;
        ro) echo "Romania" ;;
        rs) echo "Serbia" ;;
        ru) echo "Russia" ;;
        rw) echo "Rwanda" ;;
        sa) echo "Saudi Arabia" ;;
        sb) echo "Solomon Islands" ;;
        sc) echo "Seychelles" ;;
        sd) echo "Sudan" ;;
        se) echo "Sweden" ;;
        sg) echo "Singapore" ;;
        sh) echo "Saint Helena" ;;
        si) echo "Slovenia" ;;
        sj) echo "Svalbard and Jan Mayen" ;;
        sk) echo "Slovakia" ;;
        sl) echo "Sierra Leone" ;;
        sm) echo "San Marino" ;;
        sn) echo "Senegal" ;;
        so) echo "Somalia" ;;
        sr) echo "Suriname" ;;
        ss) echo "South Sudan" ;;
        st) echo "Sao Tome and Principe" ;;
        sv) echo "El Salvador" ;;
        sx) echo "Sint Maarten" ;;
        sy) echo "Syria" ;;
        sz) echo "Eswatini" ;;
        tc) echo "Turks and Caicos Islands" ;;
        td) echo "Chad" ;;
        tf) echo "French Southern Territories" ;;
        tg) echo "Togo" ;;
        th) echo "Thailand" ;;
        tj) echo "Tajikistan" ;;
        tk) echo "Tokelau" ;;
        tl) echo "Timor-Leste" ;;
        tm) echo "Turkmenistan" ;;
        tn) echo "Tunisia" ;;
        to) echo "Tonga" ;;
        tr) echo "Turkey" ;;
        tt) echo "Trinidad and Tobago" ;;
        tv) echo "Tuvalu" ;;
        tw) echo "Taiwan" ;;
        tz) echo "Tanzania" ;;
        ua) echo "Ukraine" ;;
        ug) echo "Uganda" ;;
        um) echo "U.S. Minor Outlying Islands" ;;
        us) echo "United States" ;;
        uy) echo "Uruguay" ;;
        uz) echo "Uzbekistan" ;;
        va) echo "Vatican City" ;;
        vc) echo "Saint Vincent and the Grenadines" ;;
        ve) echo "Venezuela" ;;
        vg) echo "British Virgin Islands" ;;
        vi) echo "U.S. Virgin Islands" ;;
        vn) echo "Vietnam" ;;
        vu) echo "Vanuatu" ;;
        wf) echo "Wallis and Futuna" ;;
        ws) echo "Samoa" ;;
        xk) echo "Kosovo" ;;
        ye) echo "Yemen" ;;
        yt) echo "Mayotte" ;;
        za) echo "South Africa" ;;
        zm) echo "Zambia" ;;
        zw) echo "Zimbabwe" ;;
        *) echo "Unknown" ;;
    esac
}

# -----------------------------------------------------------------------------
# Show available countries
# -----------------------------------------------------------------------------

show_countries() {
    echo ""
    echo "Available countries (ISO code - name):"
    echo "======================================="
    echo ""

    local col=0
    for code in $COUNTRIES; do
        local name
        name=$(get_country_name "$code")
        printf "  %-4s %-30s" "$code" "$name"
        col=$((col + 1))
        if [ $col -eq 2 ]; then
            echo ""
            col=0
        fi
    done

    if [ $col -ne 0 ]; then
        echo ""
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Validate country code
# -----------------------------------------------------------------------------

validate_country_code() {
    local code="$1"

    # Convert to lowercase
    code=$(echo "$code" | tr '[:upper:]' '[:lower:]')

    # Check if it exists in the list
    if echo "$COUNTRIES" | grep -q "^${code}$"; then
        echo "$code"
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Download and extract data
# -----------------------------------------------------------------------------

download_and_extract() {
    local country_code="$1"
    local country_name
    country_name=$(get_country_name "$country_code")

    local download_url="${BASE_URL}/${country_code}/photon-db-${country_code}-latest.tar.bz2"
    local output_file="${SCRIPT_DIR}/photon_data.tar.bz2"
    local data_dir="${SCRIPT_DIR}/photon_data"

    echo ""
    print_info "Downloading data for: $country_name ($country_code)"
    echo "URL: $download_url"
    echo ""

    # Check if data directory already exists
    if [ -d "$data_dir" ]; then
        print_warning "The photon_data/ directory already exists."
        read -p "Do you want to overwrite it? (y/N): " confirm
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            echo "Operation cancelled."
            exit 0
        fi
        echo "Removing existing directory..."
        rm -rf "$data_dir"
    fi

    # Download file
    echo "Downloading (this may take several minutes)..."
    if ! wget --progress=bar:force -O "$output_file" "$download_url" 2>&1; then
        print_error "Error downloading file."
        rm -f "$output_file"
        exit 1
    fi

    echo ""
    print_success "Download completed."

    # Extract file
    echo ""
    echo "Extracting data (this may take several minutes)..."
    if ! tar -xjf "$output_file" -C "$SCRIPT_DIR"; then
        print_error "Error extracting file."
        rm -f "$output_file"
        exit 1
    fi

    print_success "Extraction completed."

    # Delete compressed file
    echo ""
    echo "Removing compressed file to save space..."
    rm -f "$output_file"
    print_success "Compressed file removed."

    # Verify directory was created
    if [ -d "$data_dir" ]; then
        local size
        size=$(du -sh "$data_dir" 2>/dev/null | cut -f1)
        echo ""
        print_success "Data installed successfully in photon_data/ ($size)"
    else
        print_error "photon_data/ directory not found after extraction."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Show next steps
# -----------------------------------------------------------------------------

show_next_steps() {
    echo ""
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE}  Next Steps${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
    echo "Photon data is ready. To start the server:"
    echo ""
    echo "  docker-compose up -d --build"
    echo ""
    echo "To verify it's working:"
    echo ""
    echo "  curl 'http://localhost:2322/api?q=test'"
    echo ""
    echo "Or if using nginx as proxy:"
    echo ""
    echo "  curl 'http://localhost/photon/api?q=test'"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
    print_header

    # Check dependencies
    check_dependencies

    # Get available countries
    get_available_countries

    # Show country list
    show_countries

    # Request country code
    while true; do
        read -p "Enter country code (e.g., rw, bo, us): " input_code

        if [ -z "$input_code" ]; then
            print_error "You must enter a country code."
            continue
        fi

        validated_code=$(validate_country_code "$input_code") || {
            print_error "Country code '$input_code' is not valid or not available."
            echo "Please check the list of available countries above."
            continue
        }

        break
    done

    local country_name
    country_name=$(get_country_name "$validated_code")

    # Confirm download
    echo ""
    echo "You selected: $country_name ($validated_code)"
    read -p "Continue with download? (Y/n): " confirm

    if [[ "$confirm" =~ ^[nN]$ ]]; then
        echo "Operation cancelled."
        exit 0
    fi

    # Download and extract
    download_and_extract "$validated_code"

    # Show next steps
    show_next_steps
}

# Run main
main "$@"
