# Bloom Ticketing Web Application

## Project Overview
The Bloom Ticketing Web Application is a comprehensive platform for managing and purchasing tickets for events and movies. This application is built using Python for the backend and HTML5, CSS3, and Bootstrap for the frontend. The database is managed using MySQL with XAMPP.

## Technology Stack
- **Backend**: Python (with a web framework like Flask or Django)
- **Frontend**: HTML5, CSS3, Bootstrap (latest version)
- **Database**: MySQL (using XAMPP)
- **JavaScript**: Vanilla JS with AJAX for asynchronous operations
- **Authentication**: Python-based authentication system

## Features
- **User Authentication**: Registration, login, password recovery, and role-based access control.
- **Event and Movie Browsing**: Homepage with featured events/movies carousel, browsing with filters, and detailed pages.
- **Booking System**: Multi-step booking process, seat selection, ticket type selection, promotion code application, and checkout.
- **Admin Portal**: Dashboard with KPIs, CRUD operations for all entities, user management, and reporting.
- **User Portal**: Profile management, booking history, e-tickets, loyalty points tracking, and ticket trading.
- **Theming System**: Dark/light mode with consistent UI elements.

## Setup Instructions
1. **Clone the Repository**:
   ```sh
   git clone https://github.com/benkaesy820/bloom-ticket.git
   cd bloom-ticket
   ```

2. **Set Up the Python Environment**:
   ```sh
   python -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   pip install -r requirements.txt
   ```

3. **Configure the Database**:
   - Create a MySQL database named `bloom_db`.
   - Update the `.env` file with your database credentials.
   - Run the database migrations:
     ```sh
     flask db upgrade
     ```

4. **Run the Application**:
   ```sh
   flask run
   ```

## Development Guidelines
- Follow the project structure outlined in the development plan.
- Use consistent naming conventions and coding standards.
- Write unit tests for all Python functions.
- Conduct integration testing for module interactions.
- Ensure UI responsiveness and cross-browser compatibility.
- Perform security testing and penetration testing.

## Contributing
1. Fork the repository.
2. Create a new branch: `git checkout -b feature-branch-name`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin feature-branch-name`
5. Submit a pull request.

## License
This project is licensed under the MIT License.
