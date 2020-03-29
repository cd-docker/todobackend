from django.conf.urls import url, include
from rest_framework.routers import DefaultRouter

from todo import views

# Create a router and register our viewsets with it.
router = DefaultRouter(trailing_slash=False)
router.register(r'todos', views.TodoItemViewSet)

# The API URLs are now determined automatically by the router.
urlpatterns = [
    url('', include(router.urls)),
]