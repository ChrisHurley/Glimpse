﻿using System.Collections.Generic;
using System.Reflection;
using System.Web.Mvc;
using System.Web.Mvc.Async;
using Glimpse.Core.Extensibility;
using Glimpse.Core.Message;
using Glimpse.Mvc.Message;

namespace Glimpse.Mvc.AlternateType
{
    public class AsyncActionInvoker : AlternateType<IAsyncActionInvoker>
    {
        private IEnumerable<IAlternateMethod> allMethods;

        public AsyncActionInvoker(IProxyFactory proxyFactory) : base(proxyFactory)
        {
        }

        public override IEnumerable<IAlternateMethod> AllMethods
        {
            get
            {
                return allMethods ?? (allMethods = new List<IAlternateMethod>
                    {
                        new BeginInvokeActionMethod(),
                        new EndInvokeActionMethod(),
                        new ActionInvoker.InvokeActionResult<AsyncControllerActionInvoker>(),
                        new ActionInvoker.GetFilters<AsyncControllerActionInvoker>(new ActionFilter(ProxyFactory), new ResultFilter(ProxyFactory), new AuthorizationFilter(ProxyFactory), new ExceptionFilter(ProxyFactory))
                    });
            }
        }

        public override bool TryCreate(IAsyncActionInvoker originalObj, out IAsyncActionInvoker newObj, IEnumerable<object> mixins, object[] constructorArgs)
        {
            if (originalObj == null)
            {
                newObj = null;
                return false;
            }

            var originalType = originalObj.GetType();

            if (originalType == typeof(AsyncControllerActionInvoker) && ProxyFactory.IsExtendClassEligible(originalType))
            {
                newObj = ProxyFactory.ExtendClass<AsyncControllerActionInvoker>(AllMethods, new[] { new ActionInvokerStateMixin() });
                return true;
            }

            if (originalObj is AsyncControllerActionInvoker && ProxyFactory.IsWrapClassEligible(originalType))
            {
                newObj = ProxyFactory.WrapClass((AsyncControllerActionInvoker)originalObj, AllMethods, new object[] { new ActionInvokerStateMixin() });
                return true;
            }

            if (ProxyFactory.IsWrapInterfaceEligible<IAsyncActionInvoker>(originalType))
            {
                newObj = ProxyFactory.WrapInterface(originalObj, AllMethods, new[] { new ActionInvokerStateMixin() });
                return true;
            }

            newObj = null;
            return false;
        }

        public class BeginInvokeActionMethod : IAlternateMethod
        {
            public BeginInvokeActionMethod()
            {
                MethodToImplement = typeof(AsyncControllerActionInvoker).GetMethod("BeginInvokeActionMethod", BindingFlags.Instance | BindingFlags.NonPublic);
            }

            public MethodInfo MethodToImplement { get; private set; }

            public void NewImplementation(IAlternateMethodContext context)
            {
                // BeginInvokeActionMethod(ControllerContext controllerContext, ActionDescriptor actionDescriptor, IDictionary<string, object> parameters, AsyncCallback callback, object state)
                if (context.RuntimePolicyStrategy() == RuntimePolicy.Off)
                {
                    context.Proceed();
                    return;
                }

                var state = (IActionInvokerStateMixin)context.Proxy;
                var timer = context.TimerStrategy();
                state.Arguments = new ActionInvoker.InvokeActionMethod.Arguments(context.Arguments);
                state.Offset = timer.Start();
                context.Proceed();
            }
        }

        public class EndInvokeActionMethod : IAlternateMethod
        {
            public EndInvokeActionMethod()
            {
                MethodToImplement = typeof(AsyncControllerActionInvoker).GetMethod("EndInvokeActionMethod", BindingFlags.Instance | BindingFlags.NonPublic);
            }

            public MethodInfo MethodToImplement { get; private set; }

            public void NewImplementation(IAlternateMethodContext context)
            {
                if (context.RuntimePolicyStrategy() == RuntimePolicy.Off)
                {
                    context.Proceed();
                    return;
                }

                context.Proceed();
                var state = (IActionInvokerStateMixin)context.Proxy;
                var timer = context.TimerStrategy();
                var timerResult = timer.Stop(state.Offset);

                var message = new ActionInvoker.InvokeActionMethod.Message(context.ReturnValue.GetType())
                    .AsTimedMessage(timerResult)
                    .AsSourceMessage(context.InvocationTarget.GetType(), context.MethodInvocationTarget)
                    .AsChildActionMessage(state.Arguments.ControllerContext)
                    .AsActionMessage(state.Arguments.ControllerContext)
                    .AsMvcTimelineMessage(Glimpse.Mvc.Message.Timeline.Filter);

                context.MessageBroker.Publish(message);
            }
        }
    }
}