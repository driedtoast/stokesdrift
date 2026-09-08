import { VNode } from 'preact';
import { Router, Route } from 'preact-router';
import { isAuthenticated, currentUser, currentTeam } from './lib/store';
import { Header } from './components/Header';
import { LoginPage } from './pages/LoginPage';
import { SignupPage } from './pages/SignupPage';
import { DashboardPage } from './pages/DashboardPage';
import { ItemsPage } from './pages/ItemsPage';
import { ItemDetailPage } from './pages/ItemDetailPage';
import { LocationsPage } from './pages/LocationsPage';
import { LocationDetailPage } from './pages/LocationDetailPage';
import { AddItemPage } from './pages/AddItemPage';
import { AddLocationPage } from './pages/AddLocationPage';

function ProtectedRoute({ component: Component, ...props }: { component: VNode; [key: string]: unknown }) {
  if (!isAuthenticated.value) {
    return <LoginPage />;
  }
  return Component;
}

export function App() {
  return (
    <div class="min-h-screen bg-neutral">
      <Header />
      <main class="max-w-7xl mx-auto px-4 lg:px-12 py-8">
        <Router>
          <Route path="/" component={isAuthenticated.value ? DashboardPage : LoginPage} />
          <Route path="/login" component={LoginPage} />
          <Route path="/signup" component={SignupPage} />
          <Route path="/items" component={ItemsPage} />
          <Route path="/items/add" component={AddItemPage} />
          <Route path="/items/:id" component={ItemDetailPage} />
          <Route path="/locations" component={LocationsPage} />
          <Route path="/locations/add" component={AddLocationPage} />
          <Route path="/locations/:id" component={LocationDetailPage} />
        </Router>
      </main>
    </div>
  );
}